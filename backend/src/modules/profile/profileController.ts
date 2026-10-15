import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { pool, query } from '../../config/db.js';
import { NutritionCalculator } from '../nutrition/nutritionCalculator.js';

const updateProfileSchema = z.object({
  name: z.string().trim().min(2).max(100).optional(),
  age: z.number().int().min(18, 'Usia minimal 18 tahun').max(120, 'Usia maksimal 120 tahun').optional(),
  gender: z.enum(['male', 'female', 'neutral']).optional(),
  heightCm: z.number().min(100).max(250).optional(),
  weightKg: z.number().min(30).max(300).optional(),
  activityLevel: z.enum(['sedentary', 'light', 'moderate', 'heavy', 'very_heavy']).optional(),
  goal: z.enum(['lose', 'maintain', 'gain', 'fitness', 'muscle']).optional(),
  targetWeightKg: z.number().min(30).max(300).nullable().optional(),
  trainingExperience: z.enum(['beginner', 'intermediate', 'advanced']).optional(),
  trainingDaysPerWeek: z.number().int().min(1).max(7).optional(),
  trainingSchedule: z.array(z.enum(['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'])).max(7).optional(),
  availableEquipment: z.array(z.string().trim().min(1).max(80)).max(30).optional(),
  foodPreferences: z.array(z.string().trim().min(1).max(80)).max(30).optional(),
  allergies: z.array(z.string().trim().min(1).max(80)).max(30).optional(),
  dietaryRestrictions: z.array(z.string().trim().min(1).max(80)).max(30).optional(),
  activityLimitations: z.string().trim().max(1000).nullable().optional(),
  onboardingCompleted: z.boolean().optional(),
  timezone: z.string().optional(),
});

const manualTargetSchema = z.object({
  targetCalories: z.number().int().min(1200, 'Batas aman kalori harian minimal 1200 kkal.'),
  targetProteinG: z.number().min(20).max(500),
  targetCarbsG: z.number().min(20).max(1000),
  targetFatG: z.number().min(10).max(300),
  targetWaterMl: z.number().int().min(1000).max(10000),
});

export class ProfileController {
  static async getProfile(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const userRes = await query(
        `SELECT id, email, name, age, gender, height_cm, weight_kg, target_weight_kg,
                activity_level, goal, training_experience, training_days_per_week, training_schedule,
                available_equipment, food_preferences, allergies, dietary_restrictions,
                activity_limitations, onboarding_completed, onboarding_completed_at, timezone, created_at
         FROM users WHERE id = $1`,
        [userId]
      );
      if (userRes.rows.length === 0) {
        return res.status(404).json({ success: false, error: { code: 'USER_NOT_FOUND', message: 'Pengguna tidak ditemukan.' } });
      }

      const targetsRes = await query('SELECT * FROM user_nutrition_targets WHERE user_id = $1', [userId]);

      res.json({
        success: true,
        data: {
          user: userRes.rows[0],
          nutritionTargets: targetsRes.rows[0] || null,
        },
      });
    } catch (err) {
      next(err);
    }
  }

  static async updateProfile(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const validated = updateProfileSchema.parse(req.body);

      // Fetch current user
      const client = await pool.connect();
      let updatedUser;
      let targets;
      try {
        await client.query('BEGIN');
        const current = (await client.query('SELECT * FROM users WHERE id = $1 FOR UPDATE', [userId])).rows[0];
        if (!current) {
          await client.query('ROLLBACK');
          return res.status(404).json({ success: false, error: { code: 'USER_NOT_FOUND', message: 'Pengguna tidak ditemukan.' } });
        }

        const values = [
          validated.name?.trim() ?? current.name,
          validated.age ?? current.age,
          validated.gender ?? current.gender,
          validated.heightCm ?? current.height_cm,
          validated.weightKg ?? current.weight_kg,
          validated.activityLevel ?? current.activity_level,
          validated.goal ?? current.goal,
          validated.timezone ?? current.timezone,
          validated.targetWeightKg === undefined ? current.target_weight_kg : validated.targetWeightKg,
          validated.trainingExperience ?? current.training_experience,
          validated.trainingDaysPerWeek ?? current.training_days_per_week,
          JSON.stringify(validated.trainingSchedule ?? current.training_schedule),
          validated.availableEquipment ?? current.available_equipment,
          validated.foodPreferences ?? current.food_preferences,
          validated.allergies ?? current.allergies,
          validated.dietaryRestrictions ?? current.dietary_restrictions,
          validated.activityLimitations === undefined ? current.activity_limitations : validated.activityLimitations,
          validated.onboardingCompleted ?? current.onboarding_completed,
          validated.onboardingCompleted === true ? new Date() : validated.onboardingCompleted === false ? null : current.onboarding_completed_at,
          userId,
        ];
        await client.query(
          `UPDATE users SET name = $1, age = $2, gender = $3, height_cm = $4, weight_kg = $5,
             activity_level = $6, goal = $7, timezone = $8, target_weight_kg = $9,
             training_experience = $10, training_days_per_week = $11, training_schedule = $12::jsonb,
             available_equipment = $13, food_preferences = $14, allergies = $15,
             dietary_restrictions = $16, activity_limitations = $17, onboarding_completed = $18,
             onboarding_completed_at = $19, updated_at = NOW()
           WHERE id = $20`,
          values,
        );

        const age = Number(values[1]);
        const gender = String(values[2]);
        const heightCm = Number(values[3]);
        const weightKg = Number(values[4]);
        const activityLevel = String(values[5]);
        const goal = String(values[6]);
        const currentTarget = (await client.query('SELECT is_manual FROM user_nutrition_targets WHERE user_id = $1', [userId])).rows[0];
        if (!currentTarget?.is_manual && Number.isFinite(age) && Number.isFinite(heightCm) && Number.isFinite(weightKg)) {
          const newTargets = NutritionCalculator.calculateTargets({ age, gender, heightCm, weightKg, activityLevel, goal });
          await client.query(
            `INSERT INTO user_nutrition_targets (user_id, target_calories, target_protein_g, target_carbs_g, target_fat_g, target_water_ml, is_manual)
             VALUES ($1, $2, $3, $4, $5, $6, FALSE)
             ON CONFLICT (user_id) DO UPDATE
             SET target_calories = EXCLUDED.target_calories, target_protein_g = EXCLUDED.target_protein_g,
                 target_carbs_g = EXCLUDED.target_carbs_g, target_fat_g = EXCLUDED.target_fat_g,
                 target_water_ml = EXCLUDED.target_water_ml, updated_at = NOW()`,
            [userId, newTargets.targetCalories, newTargets.targetProteinG, newTargets.targetCarbsG, newTargets.targetFatG, newTargets.targetWaterMl],
          );
        }
        updatedUser = (await client.query(
          `SELECT id, email, name, age, gender, height_cm, weight_kg, target_weight_kg,
                  activity_level, goal, training_experience, training_days_per_week, training_schedule,
                  available_equipment, food_preferences, allergies, dietary_restrictions,
                  activity_limitations, onboarding_completed, onboarding_completed_at, timezone, created_at, updated_at
           FROM users WHERE id = $1`,
          [userId],
        )).rows[0];
        targets = (await client.query('SELECT * FROM user_nutrition_targets WHERE user_id = $1', [userId])).rows[0];
        await client.query('COMMIT');
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      } finally {
        client.release();
      }

      res.json({
        success: true,
        data: {
          user: updatedUser,
          nutritionTargets: targets,
        },
        message: 'Profil berhasil diperbarui.',
      });
    } catch (err) {
      next(err);
    }
  }

  static async getTargets(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const targetsRes = await query('SELECT * FROM user_nutrition_targets WHERE user_id = $1', [userId]);
      res.json({
        success: true,
        data: targetsRes.rows[0] || null,
      });
    } catch (err) {
      next(err);
    }
  }

  static async updateManualTargets(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const validated = manualTargetSchema.parse(req.body);
      const profile = (await query('SELECT gender FROM users WHERE id = $1', [userId])).rows[0];
      const minimumCalories = profile?.gender === 'female' ? 1200 : 1500;
      if (validated.targetCalories < minimumCalories) {
        return res.status(422).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: `Batas aman target kalori harian untuk profil ini minimal ${minimumCalories} kkal.`,
          },
        });
      }

      await query(
        `INSERT INTO user_nutrition_targets (user_id, target_calories, target_protein_g, target_carbs_g, target_fat_g, target_water_ml, is_manual)
         VALUES ($1, $2, $3, $4, $5, $6, TRUE)
         ON CONFLICT (user_id) DO UPDATE
         SET target_calories = EXCLUDED.target_calories,
             target_protein_g = EXCLUDED.target_protein_g,
             target_carbs_g = EXCLUDED.target_carbs_g,
             target_fat_g = EXCLUDED.target_fat_g,
             target_water_ml = EXCLUDED.target_water_ml,
             is_manual = TRUE,
             updated_at = NOW()`,
        [userId, validated.targetCalories, validated.targetProteinG, validated.targetCarbsG, validated.targetFatG, validated.targetWaterMl]
      );

      const targets = (await query('SELECT * FROM user_nutrition_targets WHERE user_id = $1', [userId])).rows[0];

      res.json({
        success: true,
        data: targets,
        message: 'Target nutrisi kustom berhasil disimpan.',
      });
    } catch (err) {
      next(err);
    }
  }
}
