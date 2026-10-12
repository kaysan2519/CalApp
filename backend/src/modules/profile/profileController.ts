import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { query } from '../../config/db.js';
import { NutritionCalculator } from '../nutrition/nutritionCalculator.js';

const updateProfileSchema = z.object({
  name: z.string().min(2).optional(),
  age: z.number().int().min(18, 'Usia minimal 18 tahun').optional(),
  gender: z.enum(['male', 'female', 'neutral']).optional(),
  heightCm: z.number().min(100).max(250).optional(),
  weightKg: z.number().min(30).max(300).optional(),
  activityLevel: z.enum(['sedentary', 'light', 'moderate', 'heavy', 'very_heavy']).optional(),
  goal: z.enum(['lose', 'maintain', 'gain']).optional(),
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
        'SELECT id, email, name, age, gender, height_cm, weight_kg, activity_level, goal, timezone, created_at FROM users WHERE id = $1',
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
      const current = (await query('SELECT * FROM users WHERE id = $1', [userId])).rows[0];
      if (!current) {
        return res.status(404).json({ success: false, error: { code: 'USER_NOT_FOUND', message: 'Pengguna tidak ditemukan.' } });
      }

      const name = validated.name ?? current.name;
      const age = validated.age ?? current.age;
      const gender = validated.gender ?? current.gender;
      const heightCm = validated.heightCm ?? current.height_cm;
      const weightKg = validated.weightKg ?? current.weight_kg;
      const activityLevel = validated.activityLevel ?? current.activity_level;
      const goal = validated.goal ?? current.goal;
      const timezone = validated.timezone ?? current.timezone;

      await query(
        `UPDATE users
         SET name = $1, age = $2, gender = $3, height_cm = $4, weight_kg = $5, activity_level = $6, goal = $7, timezone = $8, updated_at = NOW()
         WHERE id = $9`,
        [name, age, gender, heightCm, weightKg, activityLevel, goal, timezone, userId]
      );

      // Check if targets should be recalculated
      const currentTarget = (await query('SELECT is_manual FROM user_nutrition_targets WHERE user_id = $1', [userId])).rows[0];
      let newTargets = null;

      if (!currentTarget || !currentTarget.is_manual) {
        newTargets = NutritionCalculator.calculateTargets({
          age,
          gender,
          heightCm,
          weightKg,
          activityLevel,
          goal,
        });

        await query(
          `INSERT INTO user_nutrition_targets (user_id, target_calories, target_protein_g, target_carbs_g, target_fat_g, target_water_ml, is_manual)
           VALUES ($1, $2, $3, $4, $5, $6, FALSE)
           ON CONFLICT (user_id) DO UPDATE
           SET target_calories = EXCLUDED.target_calories,
               target_protein_g = EXCLUDED.target_protein_g,
               target_carbs_g = EXCLUDED.target_carbs_g,
               target_fat_g = EXCLUDED.target_fat_g,
               target_water_ml = EXCLUDED.target_water_ml,
               updated_at = NOW()`,
          [userId, newTargets.targetCalories, newTargets.targetProteinG, newTargets.targetCarbsG, newTargets.targetFatG, newTargets.targetWaterMl]
        );
      }

      const updatedUser = (await query('SELECT id, email, name, age, gender, height_cm, weight_kg, activity_level, goal, timezone FROM users WHERE id = $1', [userId])).rows[0];
      const targets = (await query('SELECT * FROM user_nutrition_targets WHERE user_id = $1', [userId])).rows[0];

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
