import { pool } from '../../config/db.js';

type ActivityXpEvent = 'meal_logged' | 'workout_completed' | 'community_post';

export interface AwardXpResult {
  awarded: boolean;
  xpAmount: number;
  totalXp: number;
  currentLevel: number;
  reason: string;
  dailyXpEarned: number;
  dailyCapReached: boolean;
  unlockedAchievements: string[];
}

export class GamificationService {
  private readonly DAILY_XP_CAP = 500;
  private readonly RANKS = [
    { name: 'Rookie', icon: 'emoji_events', description: 'Mulai membangun kebiasaan sehat.', minXp: 0 },
    { name: 'Bronze', icon: 'military_tech', description: 'Konsisten mencatat aktivitas.', minXp: 100 },
    { name: 'Silver', icon: 'workspace_premium', description: 'Menjaga progres dari minggu ke minggu.', minXp: 500 },
    { name: 'Gold', icon: 'star', description: 'Membentuk rutinitas yang kuat.', minXp: 1_500 },
    { name: 'Platinum', icon: 'stars', description: 'Menunjukkan konsistensi jangka panjang.', minXp: 5_000 },
    { name: 'Diamond', icon: 'diamond', description: 'Mencapai progres yang luar biasa.', minXp: 15_000 },
    { name: 'Elite', icon: 'workspace_premium', description: 'Menjadi teladan kebiasaan sehat.', minXp: 50_000 },
  ] as const;

  private readonly ACTIVITY_REWARDS: Record<ActivityXpEvent, number> = {
    meal_logged: 10,
    workout_completed: 25,
    community_post: 15,
  } as const;

  async awardActivityXp(userId: string, eventCode: ActivityXpEvent, activityId: string) {
    const ownershipQueries: Record<ActivityXpEvent, string> = {
      meal_logged: 'SELECT id FROM meal_logs WHERE id = $1 AND user_id = $2',
      workout_completed: `SELECT s.id FROM workout_sessions s
        WHERE s.id = $1 AND s.user_id = $2 AND s.status = 'completed'
          AND EXISTS (SELECT 1 FROM workout_sets ws WHERE ws.session_id = s.id)`,
      community_post: 'SELECT id FROM community_posts WHERE id = $1 AND user_id = $2',
    };
    const activity = await pool.query(ownershipQueries[eventCode], [activityId, userId]);
    if (activity.rows.length === 0) {
      throw { statusCode: 404, code: 'XP_ACTIVITY_NOT_FOUND', message: 'Aktivitas tercatat tidak ditemukan untuk akun ini.' };
    }

    return this.awardXp(
      userId,
      eventCode,
      this.ACTIVITY_REWARDS[eventCode],
      `activity:${userId}:${eventCode}:${activityId}`,
      { activityId },
    );
  }

  /**
   * Calculate current level from total XP using a progressive formula:
   * Level 1: 0 - 99 XP
   * Level 2: 100 - 399 XP
   * Level 3: 400 - 899 XP
   * Level L: requires 100 * (L - 1)^2 XP
   */
  public calculateLevel(totalXp: number): number {
    if (totalXp <= 0) return 1;
    return Math.floor(Math.sqrt(totalXp / 100)) + 1;
  }

  public getXpRequiredForLevel(level: number): number {
    if (level <= 1) return 0;
    return 100 * Math.pow(level - 1, 2);
  }

  /**
   * Award XP to a user with idempotency check, daily cap (500 XP), and auto-leveling
   */
  private async awardXp(
    userId: string,
    eventCode: string,
    requestedXp: number,
    idempotencyKey: string,
    metadata: Record<string, unknown> = {}
  ): Promise<AwardXpResult> {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // Lock the user's XP row before reading the cap or idempotency key.
      // This serializes concurrent awards for the same account.
      const currentProfile = await this.getOrCreateUserXp(client, userId);

      // 1. Check idempotency
      const existingEvent = await client.query(
        'SELECT id, xp_amount, created_at FROM xp_audit_logs WHERE user_id = $1 AND idempotency_key = $2',
        [userId, idempotencyKey]
      );

      if (existingEvent.rows.length > 0) {
        // Already processed
        const dailyXp = await this.getDailyXpTotal(client, userId);
        await client.query('COMMIT');

        return {
          awarded: false,
          xpAmount: existingEvent.rows[0].xp_amount,
          totalXp: currentProfile.total_xp,
          currentLevel: currentProfile.current_level,
          reason: 'duplicate_event',
          dailyXpEarned: dailyXp,
          dailyCapReached: dailyXp >= this.DAILY_XP_CAP,
          unlockedAchievements: [],
        };
      }

      // 2. Check Daily XP Cap
      const dailyEarned = await this.getDailyXpTotal(client, userId);
      const remainingQuota = Math.max(0, this.DAILY_XP_CAP - dailyEarned);

      if (remainingQuota <= 0) {
        // Daily cap already reached, record audit log with 0 XP awarded
        await client.query(
          `INSERT INTO xp_audit_logs (user_id, event_code, xp_amount, idempotency_key, metadata)
           VALUES ($1, $2, 0, $3, $4)`,
          [userId, eventCode, idempotencyKey, JSON.stringify({ ...metadata, capped: true })]
        );

        await client.query('COMMIT');

        return {
          awarded: false,
          xpAmount: 0,
          totalXp: currentProfile.total_xp,
          currentLevel: currentProfile.current_level,
          reason: 'daily_cap_reached',
          dailyXpEarned: dailyEarned,
          dailyCapReached: true,
          unlockedAchievements: [],
        };
      }

      // Actual XP to award
      const actualXp = Math.min(requestedXp, remainingQuota);

      // 3. Insert audit log
      await client.query(
        `INSERT INTO xp_audit_logs (user_id, event_code, xp_amount, idempotency_key, metadata)
         VALUES ($1, $2, $3, $4, $5)`,
        [userId, eventCode, actualXp, idempotencyKey, JSON.stringify(metadata)]
      );

      // 4. Update user_xp table
      const newTotalXp = currentProfile.total_xp + actualXp;
      const newLevel = this.calculateLevel(newTotalXp);

      // Update streaks if active today
      const today = new Date().toISOString().slice(0, 10);
      let newStreak = currentProfile.current_streak_days;

      if (currentProfile.last_activity_date) {
        const lastDate = new Date(currentProfile.last_activity_date).toISOString().slice(0, 10);
        const lastDateTime = new Date(lastDate).getTime();
        const todayTime = new Date(today).getTime();
        const diffDays = Math.round((todayTime - lastDateTime) / (1000 * 60 * 60 * 24));

        if (diffDays === 1) {
          newStreak += 1;
        } else if (diffDays > 1) {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }

      await client.query(
        `UPDATE user_xp
         SET total_xp = $1, current_level = $2, current_streak_days = $3, last_activity_date = $4, updated_at = NOW()
         WHERE user_id = $5`,
        [newTotalXp, newLevel, newStreak, today, userId]
      );

      // 5. Evaluate achievements
      const newlyUnlocked = await this.evaluateAchievements(client, userId, eventCode, newStreak);

      await client.query('COMMIT');

      const updatedDailyTotal = dailyEarned + actualXp;

      return {
        awarded: true,
        xpAmount: actualXp,
        totalXp: newTotalXp,
        currentLevel: newLevel,
        reason: 'success',
        dailyXpEarned: updatedDailyTotal,
        dailyCapReached: updatedDailyTotal >= this.DAILY_XP_CAP,
        unlockedAchievements: newlyUnlocked,
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  private async getOrCreateUserXp(client: any, userId: string) {
    await client.query(
      `INSERT INTO user_xp (user_id, total_xp, current_level, current_streak_days)
       VALUES ($1, 0, 1, 0) ON CONFLICT (user_id) DO NOTHING`,
      [userId],
    );
    const profile = await client.query('SELECT * FROM user_xp WHERE user_id = $1 FOR UPDATE', [userId]);
    if (profile.rows.length === 0) throw new Error('Could not initialize XP profile for user.');
    return profile.rows[0];
  }

  private async getDailyXpTotal(client: any, userId: string): Promise<number> {
    const res = await client.query(
      `SELECT COALESCE(SUM(xp_amount), 0) as daily_total
       FROM xp_audit_logs
       WHERE user_id = $1
         AND created_at >= date_trunc('day', NOW() AT TIME ZONE 'Asia/Jakarta') AT TIME ZONE 'Asia/Jakarta'
         AND created_at < (date_trunc('day', NOW() AT TIME ZONE 'Asia/Jakarta') + INTERVAL '1 day') AT TIME ZONE 'Asia/Jakarta'`,
      [userId]
    );
    return parseInt(res.rows[0].daily_total, 10) || 0;
  }

  private async evaluateAchievements(client: any, userId: string, eventCode: string, streakDays: number): Promise<string[]> {
    const unlocked: string[] = [];

    // Helper to award achievement
    const awardAch = async (code: string) => {
      const ach = await client.query('SELECT id, title, xp_reward FROM achievements WHERE code = $1', [code]);
      if (ach.rows.length === 0) return;

      const achId = ach.rows[0].id;
      const alreadyHave = await client.query(
        'SELECT id FROM user_achievements WHERE user_id = $1 AND achievement_id = $2',
        [userId, achId]
      );

      if (alreadyHave.rows.length === 0) {
        await client.query(
          'INSERT INTO user_achievements (user_id, achievement_id) VALUES ($1, $2)',
          [userId, achId]
        );
        unlocked.push(ach.rows[0].title);
      }
    };

    if (eventCode === 'log_meal' || eventCode === 'meal_logged') {
      await awardAch('FIRST_MEAL');
    }
    if (eventCode === 'workout_completed' || eventCode === 'log_workout') {
      await awardAch('FIRST_WORKOUT');
    }
    if (eventCode === 'hydration_goal') {
      await awardAch('HYDRATION_HERO');
    }
    if (streakDays >= 3) {
      await awardAch('STREAK_3_DAYS');
    }
    if (streakDays >= 7) {
      await awardAch('STREAK_7_DAYS');
    }

    return unlocked;
  }

  /**
   * Get user gamification profile summary
   */
  async getUserProfile(userId: string) {
    const client = await pool.connect();
    try {
      const profile = await this.getOrCreateUserXp(client, userId);
      const dailyEarned = await this.getDailyXpTotal(client, userId);
      const nextLevelXp = this.getXpRequiredForLevel(profile.current_level + 1);
      const currentLevelBaseXp = this.getXpRequiredForLevel(profile.current_level);

      const progressInLevel = profile.total_xp - currentLevelBaseXp;
      const neededForNext = Math.max(1, nextLevelXp - currentLevelBaseXp);
      const levelProgressRatio = Math.min(1.0, Math.max(0.0, progressInLevel / neededForNext));
      let currentRankIndex = 0;
      for (let index = 0; index < this.RANKS.length; index += 1) {
        if (profile.total_xp >= this.RANKS[index].minXp) currentRankIndex = index;
      }
      const currentRank = this.RANKS[currentRankIndex];
      const nextRank = this.RANKS[currentRankIndex + 1] ?? null;
      const xpHistory = await client.query(
        `SELECT event_code, xp_amount, metadata, created_at FROM xp_audit_logs
         WHERE user_id = $1 AND xp_amount > 0 ORDER BY created_at DESC LIMIT 20`,
        [userId],
      );

      // Achievements count
      const achCountRes = await client.query(
        'SELECT COUNT(*) as count FROM user_achievements WHERE user_id = $1',
        [userId]
      );
      const totalAchievements = parseInt(achCountRes.rows[0].count, 10) || 0;

      return {
        totalXp: profile.total_xp,
        currentLevel: profile.current_level,
        currentStreakDays: profile.current_streak_days,
        dailyXpEarned: dailyEarned,
        dailyXpCap: this.DAILY_XP_CAP,
        currentLevelBaseXp,
        nextLevelXp,
        levelProgressRatio,
        unlockedAchievementsCount: totalAchievements,
        currentRank: {
          ...currentRank,
          nextRankName: nextRank?.name ?? null,
          nextRankXp: nextRank?.minXp ?? null,
          progressRatio: nextRank
            ? Math.min(1, Math.max(0, (profile.total_xp - currentRank.minXp) / (nextRank.minXp - currentRank.minXp)))
            : 1,
          xpToNextRank: nextRank ? Math.max(0, nextRank.minXp - profile.total_xp) : 0,
        },
        ranks: this.RANKS,
        xpHistory: xpHistory.rows,
      };
    } finally {
      client.release();
    }
  }

  /**
   * Get all achievements catalog with user unlock status
   */
  async getAchievements(userId: string) {
    const res = await pool.query(
      `SELECT a.id, a.code, a.title, a.description, a.icon_name, a.xp_reward,
              (ua.id IS NOT NULL) as is_unlocked,
              ua.unlocked_at
       FROM achievements a
       LEFT JOIN user_achievements ua ON a.id = ua.achievement_id AND ua.user_id = $1
       ORDER BY a.xp_reward ASC, a.title ASC`,
      [userId]
    );

    return res.rows;
  }

  /**
   * Weekly leaderboard with canonical Asia/Jakarta timezone and deterministic tie-breaking
   */
  async getLeaderboard(userId: string, limit = 50, period: 'weekly' | 'global' = 'weekly') {
    const scores = period === 'global'
      ? `scores AS (
           SELECT user_id, total_xp AS score, updated_at AS earliest_time
           FROM user_xp WHERE total_xp > 0
         )`
      : `scores AS (
           SELECT x.user_id, SUM(x.xp_amount)::INTEGER AS score, MIN(x.created_at) AS earliest_time
           FROM xp_audit_logs x
           WHERE x.xp_amount > 0
             AND x.created_at >= date_trunc('week', NOW() AT TIME ZONE 'Asia/Jakarta') AT TIME ZONE 'Asia/Jakarta'
           GROUP BY x.user_id
         )`;
    const rankQuery = `
      WITH ${scores}, ranked_users AS (
        SELECT u.id AS user_id, u.name AS display_name, s.score AS week_xp,
               COALESCE(ux.current_level, 1) AS current_level,
               RANK() OVER (ORDER BY s.score DESC, s.earliest_time ASC, u.id ASC)::INTEGER AS rank,
               LAG(s.score) OVER (ORDER BY s.score DESC, s.earliest_time ASC, u.id ASC) AS score_ahead
        FROM scores s
        JOIN users u ON u.id = s.user_id
        LEFT JOIN user_xp ux ON u.id = ux.user_id
      )
      SELECT user_id, display_name, week_xp, current_level, rank,
             CASE WHEN rank = 1 THEN NULL ELSE score_ahead - week_xp END AS points_to_next_rank
      FROM ranked_users ORDER BY rank ASC LIMIT $1`;
    const userRankQuery = `
      WITH ${scores}, ranked_users AS (
        SELECT u.id AS user_id, u.name AS display_name, s.score AS week_xp,
               COALESCE(ux.current_level, 1) AS current_level,
               RANK() OVER (ORDER BY s.score DESC, s.earliest_time ASC, u.id ASC)::INTEGER AS rank,
               LAG(s.score) OVER (ORDER BY s.score DESC, s.earliest_time ASC, u.id ASC) AS score_ahead
        FROM scores s
        JOIN users u ON u.id = s.user_id
        LEFT JOIN user_xp ux ON u.id = ux.user_id
      ) SELECT user_id, display_name, week_xp, current_level, rank,
               CASE WHEN rank = 1 THEN NULL ELSE score_ahead - week_xp END AS points_to_next_rank
        FROM ranked_users WHERE user_id = $1`;
    const [res, userRankRes] = await Promise.all([
      pool.query(rankQuery, [limit]),
      pool.query(userRankQuery, [userId]),
    ]);

    return {
      period,
      canonicalTimezone: 'Asia/Jakarta',
      leaderboard: res.rows,
      currentUserRank: userRankRes.rows[0] || null,
    };
  }

  /**
   * Get active challenges and user progress
   */
  async getChallenges(userId: string) {
    const res = await pool.query(
      `SELECT c.id, c.title, c.description, c.challenge_type, c.target_metric, c.target_value, c.xp_reward,
              c.starts_at, c.ends_at,
              COALESCE(uc.current_progress, 0) as current_progress,
              COALESCE(uc.is_completed, FALSE) as is_completed
       FROM challenges c
       LEFT JOIN user_challenges uc ON c.id = uc.challenge_id AND uc.user_id = $1
       WHERE c.ends_at > NOW()
       ORDER BY c.ends_at ASC`,
      [userId]
    );

    return res.rows;
  }
}

export const gamificationService = new GamificationService();
