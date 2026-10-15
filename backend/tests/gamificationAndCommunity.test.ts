import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { app } from '../src/app.js';
import { pool } from '../src/config/db.js';
import { gamificationService } from '../src/modules/gamification/gamificationService.js';

describe('Phase 8 - Gamification, Community & Notifications Integration', () => {
  let authToken: string;
  let userId: string;
  let testGroupId: string;
  let testPostId: string;
  let mealActivityId: string;
  let exerciseId: string;

  beforeAll(async () => {
    // Register unique user
    const email = `gamify_${Date.now()}@example.com`;
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        email,
        password: 'Password123!',
        name: 'Budi Gamifier',
        age: 25,
        heightCm: 170,
        weightKg: 65,
      });

    expect(res.status).toBe(201);
    authToken = res.body.data.accessToken;
    userId = res.body.data.user.id;
    const exercise = await pool.query('SELECT id FROM exercises LIMIT 1');
    exerciseId = exercise.rows[0].id;

    const meal = await pool.query(
      `INSERT INTO meal_logs (user_id, log_date, meal_type) VALUES ($1, CURRENT_DATE, 'breakfast') RETURNING id`,
      [userId],
    );
    mealActivityId = meal.rows[0].id;
    await pool.query(
      `INSERT INTO meal_log_items (meal_log_id, food_name, serving_qty, serving_unit, calories, protein_g, carbs_g, fat_g)
       VALUES ($1, 'Test meal', 1, 'porsi', 400, 25, 50, 10)`,
      [mealActivityId],
    );
  });

  afterAll(async () => {
    if (userId) await pool.query('DELETE FROM users WHERE id = $1', [userId]);
  });

  describe('F16: XP, Leveling & Achievements', () => {
    it('awards XP to user and calculates level progressively', async () => {
      const res = await request(app)
        .post('/api/v1/gamification/award-xp')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          eventCode: 'meal_logged',
          activityId: mealActivityId,
          xpAmount: 100000,
        });

      expect(res.status).toBe(200);
      expect(res.body.data.awarded).toBe(true);
      expect(res.body.data.xpAmount).toBe(10);
      expect(res.body.data.totalXp).toBe(10);
      expect(res.body.data.currentLevel).toBe(1);
    });

    it('enforces idempotency for the same recorded activity', async () => {
      const workout = await pool.query(
        `INSERT INTO workout_sessions (user_id, title, status, completed_at)
         VALUES ($1, 'Verified test session', 'completed', NOW()) RETURNING id`,
        [userId],
      );
      const activityId = workout.rows[0].id;
      await pool.query(
        `INSERT INTO workout_sets (session_id, exercise_id, set_number, reps, weight_kg)
         VALUES ($1, $2, 1, 8, 20)`,
        [activityId, exerciseId],
      );
      const res1 = await request(app)
        .post('/api/v1/gamification/award-xp')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ eventCode: 'workout_completed', activityId });
      expect(res1.body.data.awarded).toBe(true);
      const totalXpAfterFirst = res1.body.data.totalXp;

      const res2 = await request(app)
        .post('/api/v1/gamification/award-xp')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ eventCode: 'workout_completed', activityId, xpAmount: 100000 });
      expect(res2.body.data.awarded).toBe(false);
      expect(res2.body.data.reason).toBe('duplicate_event');
      expect(res2.body.data.totalXp).toBe(totalXpAfterFirst);
    });

    it('enforces daily XP cap of 500 XP strictly', async () => {
      let result: any;
      for (let index = 0; index < 22; index += 1) {
        const workout = await pool.query(
          `INSERT INTO workout_sessions (user_id, title, status, completed_at)
           VALUES ($1, $2, 'completed', NOW()) RETURNING id`,
          [userId, `Cap test session ${index}`],
        );
        await pool.query(
          `INSERT INTO workout_sets (session_id, exercise_id, set_number, reps, weight_kg)
           VALUES ($1, $2, 1, 8, 20)`,
          [workout.rows[0].id, exerciseId],
        );
        result = await gamificationService.awardActivityXp(userId, 'workout_completed', workout.rows[0].id);
      }
      expect(result.dailyXpEarned).toBe(500);
      expect(result.awarded).toBe(false);
      expect(result.reason).toBe('daily_cap_reached');
      expect(result.dailyCapReached).toBe(true);
    });

    it('rejects XP claims for an activity owned by another account or not recorded', async () => {
      const res = await request(app)
        .post('/api/v1/gamification/award-xp')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ eventCode: 'workout_completed', activityId: '00000000-0000-4000-8000-000000000001', xpAmount: 500000 });
      expect(res.status).toBe(404);
      expect(res.body.error.code).toBe('XP_ACTIVITY_NOT_FOUND');
    });

    it('fetches gamification profile and achievements list', async () => {
      const resProfile = await request(app)
        .get('/api/v1/gamification/profile')
        .set('Authorization', `Bearer ${authToken}`);

      expect(resProfile.status).toBe(200);
      expect(resProfile.body.data.totalXp).toBeGreaterThanOrEqual(500);
      expect(resProfile.body.data.currentLevel).toBeGreaterThanOrEqual(2);
      expect(resProfile.body.data.dailyXpCap).toBe(500);
      expect(resProfile.body.data.currentRank.name).toBe('Silver');
      expect(resProfile.body.data.xpHistory.length).toBeGreaterThan(0);

      const resAch = await request(app)
        .get('/api/v1/gamification/achievements')
        .set('Authorization', `Bearer ${authToken}`);

      expect(resAch.status).toBe(200);
      expect(Array.isArray(resAch.body.data)).toBe(true);
      expect(resAch.body.data.length).toBeGreaterThan(0);
    });
  });

  describe('F17: Leaderboard & Challenges', () => {
    it('returns weekly leaderboard with rank and canonical timezone Asia/Jakarta', async () => {
      const res = await request(app)
        .get('/api/v1/gamification/leaderboard')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.period).toBe('weekly');
      expect(res.body.data.canonicalTimezone).toBe('Asia/Jakarta');
      expect(Array.isArray(res.body.data.leaderboard)).toBe(true);
      expect(res.body.data.currentUserRank).toBeDefined();
      expect(res.body.data.currentUserRank.points_to_next_rank).toBeDefined();
      const global = await request(app)
        .get('/api/v1/gamification/leaderboard?period=global')
        .set('Authorization', `Bearer ${authToken}`);
      expect(global.status).toBe(200);
      expect(global.body.data.period).toBe('global');
    });

    it('returns active challenges catalog', async () => {
      const res = await request(app)
        .get('/api/v1/gamification/challenges')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body.data)).toBe(true);
    });
  });

  describe('F18: Community Groups, Posts, Reactions & Moderation', () => {
    it('creates community group and lists available groups', async () => {
      const resCreate = await request(app)
        .post('/api/v1/community/groups')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Pejuang Defisit Santai',
          description: 'Grup saling menyemangati pola makan seimbang tanpa stres',
          isPrivate: false,
        });

      expect(resCreate.status).toBe(201);
      testGroupId = resCreate.body.data.id;
      expect(resCreate.body.data.name).toBe('Pejuang Defisit Santai');

      const resList = await request(app)
        .get('/api/v1/community/groups')
        .set('Authorization', `Bearer ${authToken}`);

      expect(resList.status).toBe(200);
      expect(resList.body.data.some((g: any) => g.id === testGroupId)).toBe(true);
    });

    it('creates a feed post and lists posts with kudos and author info', async () => {
      const resPost = await request(app)
        .post('/api/v1/community/posts')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          content: 'Hari ini berhasil capai target 1800 kkal dan 110g protein! Tetap semangat kawan-kawan.',
          groupId: testGroupId,
          postType: 'text',
        });

      expect(resPost.status).toBe(201);
      testPostId = resPost.body.data.id;

      const resFeed = await request(app)
        .get('/api/v1/community/posts')
        .set('Authorization', `Bearer ${authToken}`);

      expect(resFeed.status).toBe(200);
      expect(resFeed.body.data.length).toBeGreaterThan(0);
      const post = resFeed.body.data.find((p: any) => p.id === testPostId);
      expect(post).toBeDefined();
      expect(post.author_name).toBeDefined();
    });

    it('toggles reaction (kudos) and adds comments', async () => {
      // Toggle reaction ON
      const resReactOn = await request(app)
        .post(`/api/v1/community/posts/${testPostId}/reactions`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ reactionType: 'kudos' });

      expect(resReactOn.status).toBe(200);
      expect(resReactOn.body.data.reacted).toBe(true);

      // Add comment
      const resComment = await request(app)
        .post(`/api/v1/community/posts/${testPostId}/comments`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ content: 'Luar biasa bro, pertahankan konsistensinya!' });

      expect(resComment.status).toBe(201);
      expect(resComment.body.data.content).toBe('Luar biasa bro, pertahankan konsistensinya!');

      // List comments
      const resCommentList = await request(app)
        .get(`/api/v1/community/posts/${testPostId}/comments`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(resCommentList.status).toBe(200);
      expect(resCommentList.body.data.length).toBeGreaterThan(0);
    });

    it('reports content safely to moderation queue', async () => {
      const resReport = await request(app)
        .post('/api/v1/community/report')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          targetPostId: testPostId,
          reason: 'Uji coba sistem pelaporan konten pantas',
        });

      expect(resReport.status).toBe(200);
      expect(resReport.body.data.reported).toBe(true);
      expect(resReport.body.data.reportId).toBeDefined();
    });
  });

  describe('F21: Gentle Non-shaming Notification Preferences', () => {
    it('reads and updates notification reminder preferences', async () => {
      const resGet = await request(app)
        .get('/api/v1/notifications/preferences')
        .set('Authorization', `Bearer ${authToken}`);

      expect(resGet.status).toBe(200);
      expect(resGet.body.data.preferences.gentleTone).toBe(true);
      expect(resGet.body.data.scheduledReminders.length).toBeGreaterThan(0);

      // Update preferences
      const resPut = await request(app)
        .put('/api/v1/notifications/preferences')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          breakfastTime: '07:00',
          waterIntervalHours: 3,
        });

      expect(resPut.status).toBe(200);
      expect(resPut.body.data.breakfastTime).toBe('07:00');
      expect(resPut.body.data.waterIntervalHours).toBe(3);
    });
  });
});
