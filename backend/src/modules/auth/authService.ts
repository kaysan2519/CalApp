import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { query } from '../../config/db.js';
import { config } from '../../config/env.js';
import { NutritionCalculator } from '../nutrition/nutritionCalculator.js';

export interface RegisterDTO {
  email: string;
  password: string;
  name: string;
  age: number;
  gender?: 'male' | 'female' | 'neutral';
  heightCm?: number;
  weightKg?: number;
  activityLevel?: string;
  goal?: 'lose' | 'maintain' | 'gain';
  timezone?: string;
}

export class AuthService {
  static async register(dto: RegisterDTO) {
    if (dto.age < 18) {
      throw { statusCode: 422, code: 'AGE_RESTRICTION', message: 'Usia minimal 18 tahun untuk mendaftar.' };
    }

    // Check existing email
    const existing = await query('SELECT id FROM users WHERE email = $1', [dto.email.toLowerCase()]);
    if (existing.rows.length > 0) {
      throw { statusCode: 409, code: 'EMAIL_ALREADY_EXISTS', message: 'Email sudah terdaftar.' };
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(dto.password, salt);

    const gender = dto.gender || 'neutral';
    const heightCm = dto.heightCm || 170;
    const weightKg = dto.weightKg || 65;
    const activityLevel = dto.activityLevel || 'moderate';
    const goal = dto.goal || 'maintain';
    const timezone = dto.timezone || 'Asia/Jakarta';

    // Insert User
    const userRes = await query(
      `INSERT INTO users (email, password_hash, name, age, gender, height_cm, weight_kg, activity_level, goal, timezone)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING id, email, name, age, gender, height_cm, weight_kg, activity_level, goal, timezone, created_at`,
      [dto.email.toLowerCase(), passwordHash, dto.name, dto.age, gender, heightCm, weightKg, activityLevel, goal, timezone]
    );
    const user = userRes.rows[0];

    // Compute initial nutrition targets using Mifflin-St Jeor
    const targets = NutritionCalculator.calculateTargets({
      age: dto.age,
      gender,
      heightCm,
      weightKg,
      activityLevel,
      goal,
    });

    await query(
      `INSERT INTO user_nutrition_targets (user_id, target_calories, target_protein_g, target_carbs_g, target_fat_g, target_water_ml, is_manual)
       VALUES ($1, $2, $3, $4, $5, $6, FALSE)`,
      [user.id, targets.targetCalories, targets.targetProteinG, targets.targetCarbsG, targets.targetFatG, targets.targetWaterMl]
    );

    // Initialize Gamification User XP
    await query(
      `INSERT INTO user_xp (user_id, total_xp, current_level, current_streak_days, last_activity_date)
       VALUES ($1, 0, 1, 0, CURRENT_DATE)
       ON CONFLICT (user_id) DO NOTHING`,
      [user.id]
    );

    // Generate tokens
    const tokens = await this.generateTokens(user.id, user.email);

    return {
      user: {
        ...user,
        nutritionTargets: targets,
      },
      ...tokens,
    };
  }

  static async login(email: string, password: string) {
    const userRes = await query('SELECT * FROM users WHERE email = $1', [email.toLowerCase()]);
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
    let decoded: any;
    try {
      decoded = jwt.verify(rawRefreshToken, config.jwt.refreshSecret);
    } catch (_) {
      throw { statusCode: 401, code: 'INVALID_REFRESH_TOKEN', message: 'Token refresh tidak valid atau kedaluwarsa.' };
    }

    const tokenHash = crypto.createHash('sha256').update(rawRefreshToken).digest('hex');
    const existing = await query(
      'SELECT * FROM refresh_tokens WHERE user_id = $1 AND token_hash = $2 AND revoked = FALSE AND expires_at > NOW()',
      [decoded.id, tokenHash]
    );

    if (existing.rows.length === 0) {
      // Possible token reuse attack - revoke all user tokens for safety
      await query('UPDATE refresh_tokens SET revoked = TRUE WHERE user_id = $1', [decoded.id]);
      throw { statusCode: 401, code: 'TOKEN_REUSE_DETECTED', message: 'Sesi tidak aman. Silakan login kembali.' };
    }

    // Revoke old refresh token (Token Rotation)
    await query('UPDATE refresh_tokens SET revoked = TRUE WHERE id = $1', [existing.rows[0].id]);

    // Issue new pair
    return await this.generateTokens(decoded.id, decoded.email);
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

  private static async generateTokens(userId: string, email: string) {
    const accessToken = jwt.sign(
      { id: userId, email },
      config.jwt.secret,
      { expiresIn: '15m' }
    );

    const rawRefreshToken = jwt.sign(
      { id: userId, email, nonce: crypto.randomBytes(16).toString('hex') },
      config.jwt.refreshSecret,
      { expiresIn: '7d' }
    );

    const tokenHash = crypto.createHash('sha256').update(rawRefreshToken).digest('hex');
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    await query(
      'INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)',
      [userId, tokenHash, expiresAt]
    );

    return {
      accessToken,
      refreshToken: rawRefreshToken,
      tokenType: 'Bearer',
      expiresIn: 900, // 15 mins in seconds
    };
  }
}
