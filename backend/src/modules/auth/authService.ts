import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import pg from 'pg';
import { pool, query } from '../../config/db.js';
import { config } from '../../config/env.js';
import { NutritionCalculator } from '../nutrition/nutritionCalculator.js';

export interface RegisterDTO {
  email: string;
  password: string;
  name: string;
  age: number;
  gender?: 'male' | 'female' | 'neutral';
  heightCm: number;
  weightKg: number;
  activityLevel?: string;
  goal?: 'lose' | 'maintain' | 'gain' | 'fitness' | 'muscle';
  timezone?: string;
}

export class AuthService {
  static async register(dto: RegisterDTO) {
    if (dto.age < 18) {
      throw { statusCode: 422, code: 'AGE_RESTRICTION', message: 'Usia minimal 18 tahun untuk mendaftar.' };
    }

    const email = dto.email.trim().toLowerCase();
    const name = dto.name.trim();
    const heightCm = dto.heightCm;
    const weightKg = dto.weightKg;
    const gender = dto.gender || 'neutral';
    const activityLevel = dto.activityLevel || 'moderate';
    const goal = dto.goal || 'maintain';
    const timezone = dto.timezone || 'Asia/Jakarta';
    const targets = NutritionCalculator.calculateTargets({
      age: dto.age,
      gender,
      heightCm,
      weightKg,
      activityLevel,
      goal,
    });

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(dto.password, salt);

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const userRes = await client.query(
        `INSERT INTO users (email, password_hash, name, age, gender, height_cm, weight_kg, activity_level, goal, timezone, onboarding_completed, onboarding_completed_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, TRUE, NOW())
         RETURNING id, email, name, age, gender, height_cm, weight_kg, activity_level, goal, timezone, onboarding_completed, onboarding_completed_at, created_at`,
        [email, passwordHash, name, dto.age, gender, heightCm, weightKg, activityLevel, goal, timezone],
      );
      const user = userRes.rows[0];

      await client.query(
        `INSERT INTO user_nutrition_targets (user_id, target_calories, target_protein_g, target_carbs_g, target_fat_g, target_water_ml, is_manual)
         VALUES ($1, $2, $3, $4, $5, $6, FALSE)`,
        [user.id, targets.targetCalories, targets.targetProteinG, targets.targetCarbsG, targets.targetFatG, targets.targetWaterMl],
      );

      await client.query(
        `INSERT INTO user_xp (user_id, total_xp, current_level, current_streak_days, last_activity_date)
         VALUES ($1, 0, 1, 0, CURRENT_DATE)
         ON CONFLICT (user_id) DO NOTHING`,
        [user.id],
      );

      const tokens = await this.generateTokens(user.id, user.email, client);
      await client.query('COMMIT');
      return { user: { ...user, nutritionTargets: targets }, ...tokens };
    } catch (error: any) {
      await client.query('ROLLBACK');
      if (error?.code === '23505') {
        throw { statusCode: 409, code: 'EMAIL_ALREADY_EXISTS', message: 'Email sudah terdaftar.' };
      }
      throw error;
    } finally {
      client.release();
    }
  }

  static async login(email: string, password: string) {
    const userRes = await query('SELECT * FROM users WHERE LOWER(email) = $1', [email.trim().toLowerCase()]);
    if (userRes.rows.length === 0) {
      throw { statusCode: 401, code: 'INVALID_CREDENTIALS', message: 'Email atau kata sandi tidak sesuai.' };
    }

    const user = userRes.rows[0];
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      throw { statusCode: 401, code: 'INVALID_CREDENTIALS', message: 'Email atau kata sandi tidak sesuai.' };
    }

    const targetsRes = await query('SELECT * FROM user_nutrition_targets WHERE user_id = $1', [user.id]);
    const tokens = await this.generateTokens(user.id, user.email);

    const { password_hash, ...safeUser } = user;
    return {
      user: {
        ...safeUser,
        nutritionTargets: targetsRes.rows[0] || null,
      },
      ...tokens,
    };
  }

  static async refreshTokens(rawRefreshToken: string) {
    let decoded: jwt.JwtPayload & { id: string; email: string };
    try {
      const payload = jwt.verify(rawRefreshToken, config.jwt.refreshSecret);
      if (typeof payload === 'string' || typeof payload.id !== 'string' || typeof payload.email !== 'string') {
        throw new Error('Malformed refresh token');
      }
      decoded = payload as jwt.JwtPayload & { id: string; email: string };
    } catch (_) {
      throw { statusCode: 401, code: 'INVALID_REFRESH_TOKEN', message: 'Token refresh tidak valid atau kedaluwarsa.' };
    }

    const tokenHash = crypto.createHash('sha256').update(rawRefreshToken).digest('hex');
    const client = await pool.connect();
    let reused = false;
    let tokens: Awaited<ReturnType<typeof AuthService.generateTokens>> | undefined;
    try {
      await client.query('BEGIN');
      const existing = await client.query(
        'SELECT id FROM refresh_tokens WHERE user_id = $1 AND token_hash = $2 AND revoked = FALSE AND expires_at > NOW() FOR UPDATE',
        [decoded.id, tokenHash],
      );

      if (existing.rows.length === 0) {
        await client.query('UPDATE refresh_tokens SET revoked = TRUE WHERE user_id = $1', [decoded.id]);
        reused = true;
      } else {
        await client.query('UPDATE refresh_tokens SET revoked = TRUE WHERE id = $1', [existing.rows[0].id]);
        tokens = await this.generateTokens(decoded.id, decoded.email, client);
      }
      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
    if (reused || !tokens) {
      throw { statusCode: 401, code: 'TOKEN_REUSE_DETECTED', message: 'Sesi tidak aman. Silakan login kembali.' };
    }
    return tokens;
  }

  static async logout(rawRefreshToken?: string) {
    if (!rawRefreshToken) return;
    const tokenHash = crypto.createHash('sha256').update(rawRefreshToken).digest('hex');
    await query('UPDATE refresh_tokens SET revoked = TRUE WHERE token_hash = $1', [tokenHash]);
  }

  static async exportUserData(userId: string) {
    const user = (await query('SELECT id, email, name, age, gender, height_cm, weight_kg, activity_level, goal, timezone, created_at FROM users WHERE id = $1', [userId])).rows[0];
    const targets = (await query('SELECT * FROM user_nutrition_targets WHERE user_id = $1', [userId])).rows[0];
    const meals = (await query('SELECT * FROM meal_logs WHERE user_id = $1 ORDER BY log_date DESC', [userId])).rows;
    const workouts = (await query('SELECT * FROM workout_sessions WHERE user_id = $1 ORDER BY started_at DESC', [userId])).rows;
    const measurements = (await query('SELECT * FROM body_measurements WHERE user_id = $1 ORDER BY measured_date DESC', [userId])).rows;
    const xp = (await query('SELECT * FROM user_xp WHERE user_id = $1', [userId])).rows[0];

    return {
      exportedAt: new Date().toISOString(),
      user,
      nutritionTargets: targets,
      meals,
      workouts,
      bodyMeasurements: measurements,
      gamification: xp,
    };
  }

  static async deleteAccount(userId: string) {
    // Cascade delete user
    await query('DELETE FROM users WHERE id = $1', [userId]);
    return { deleted: true };
  }

  private static async generateTokens(userId: string, email: string, client: pg.PoolClient | pg.Pool = pool) {
    const accessToken = jwt.sign(
      { id: userId, email },
      config.jwt.secret,
      { expiresIn: config.jwt.expiresIn as jwt.SignOptions['expiresIn'] }
    );

    const rawRefreshToken = jwt.sign(
      { id: userId, email, nonce: crypto.randomBytes(16).toString('hex') },
      config.jwt.refreshSecret,
      { expiresIn: config.jwt.refreshExpiresIn as jwt.SignOptions['expiresIn'] }
    );

    const tokenHash = crypto.createHash('sha256').update(rawRefreshToken).digest('hex');
    const expiresAt = new Date(Date.now() + this.durationMilliseconds(config.jwt.refreshExpiresIn));

    await client.query(
      'INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)',
      [userId, tokenHash, expiresAt]
    );

    return {
      accessToken,
      refreshToken: rawRefreshToken,
      tokenType: 'Bearer',
      expiresIn: Math.floor(this.durationMilliseconds(config.jwt.expiresIn) / 1000),
    };
  }

  private static durationMilliseconds(duration: string): number {
    const match = /^(\d+)([smhd])$/.exec(duration);
    if (!match) throw new Error('JWT_REFRESH_EXPIRES_IN must use a duration such as 15m, 7h, or 30d.');
    const value = Number(match[1]);
    const unit = match[2];
    const multiplier = unit === 's' ? 1_000 : unit === 'm' ? 60_000 : unit === 'h' ? 3_600_000 : 86_400_000;
    return value * multiplier;
  }
}
