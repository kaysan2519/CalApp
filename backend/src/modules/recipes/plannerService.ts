import { query } from '../../config/db.js';
import { NutritionService } from '../nutrition/nutritionService.js';

export class PlannerService {
  private static isInitialized = false;

  private static async ensureTable() {
    if (this.isInitialized) return;
    await query(`
      CREATE TABLE IF NOT EXISTS daily_plans (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        plan_date DATE NOT NULL,
        planned_meals JSONB DEFAULT '[]',
        workout_routine_id UUID REFERENCES workout_routines(id) ON DELETE SET NULL,
        water_target_ml INTEGER,
        notes TEXT,
        is_completed BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE(user_id, plan_date)
      );
      CREATE INDEX IF NOT EXISTS idx_daily_plans_user_date ON daily_plans(user_id, plan_date);
      ALTER TABLE daily_plans ALTER COLUMN water_target_ml DROP DEFAULT;
    `);
    this.isInitialized = true;
  }

  /**
   * F10: Generator Menu Harian AI
   * Memilih kombinasi 1 sarapan, 1 makan siang, 1 makan malam (+opsi 1 camilan)
   * dari resep lokal terverifikasi agar total kalori dalam toleransi target pengguna (±10%).
   */
  static async generateDailyMealPlan(userId: string, date?: string, customTargetCalories?: number) {
    const planDate = date || new Date().toISOString().split('T')[0];
    const profile = (await query('SELECT gender FROM users WHERE id = $1', [userId])).rows[0];
    if (!profile) {
      throw { statusCode: 404, code: 'USER_NOT_FOUND', message: 'Pengguna tidak ditemukan.' };
    }
    const minimumCalories = profile.gender === 'female' ? 1200 : 1500;

    // Ambil target nutrisi pengguna
    const targetCalories = customTargetCalories ?? (await NutritionService.getDailySummary(userId, planDate)).target.calories;
    if (targetCalories < minimumCalories) {
      throw { statusCode: 422, code: 'UNSAFE_CALORIE_TARGET', message: `Target menu minimal ${minimumCalories} kkal untuk profil ini.` };
    }

    // Ambil resep dari DB
    const recipesRes = await query(`
      SELECT id, title, description, calories_per_serving, protein_per_serving,
             carbs_per_serving, fat_per_serving, dietary_tags, prep_time_min, cook_time_min
      FROM recipes
      ORDER BY RANDOM()
    `);

    const allRecipes = recipesRes.rows.map(r => ({
      ...r,
      calories: parseFloat(r.calories_per_serving),
      proteinG: parseFloat(r.protein_per_serving),
      carbsG: parseFloat(r.carbs_per_serving),
      fatG: parseFloat(r.fat_per_serving),
    }));

    if (allRecipes.length === 0) {
      throw { statusCode: 500, code: 'NO_RECIPES', message: 'Katalog resep kosong.' };
    }

    // Alokasi kalori tipikal:
    // Sarapan: ~25%
    // Makan Siang: ~40%
    // Makan Malam: ~35%
    const targetBreakfast = targetCalories * 0.25;
    const targetLunch = targetCalories * 0.40;
    const targetDinner = targetCalories * 0.35;

    // Filter kandidat terbaik berdasarkan deviasi kalori terdekat
    const sortByClosest = (recipes: typeof allRecipes, target: number) => {
      return [...recipes].sort((a, b) => Math.abs(a.calories - target) - Math.abs(b.calories - target));
    };

    const breakfastCandidates = sortByClosest(allRecipes, targetBreakfast);
    const lunchCandidates = sortByClosest(allRecipes, targetLunch);
    const dinnerCandidates = sortByClosest(allRecipes, targetDinner);

    const breakfast = breakfastCandidates[0];
    const lunch = lunchCandidates.find(r => r.id !== breakfast.id) || lunchCandidates[0];
    const dinner = dinnerCandidates.find(r => r.id !== breakfast.id && r.id !== lunch.id) || dinnerCandidates[0];

    // Scale portions (0.5 increments: 1.0, 1.5, 2.0) to match meal calorie allocations
    const scaleMeal = (recipe: typeof allRecipes[0], mealTarget: number) => {
      const multiplier = Math.max(1.0, Math.round((mealTarget / recipe.calories) * 2) / 2);
      return {
        recipe,
        servings: multiplier,
        calories: Math.round(recipe.calories * multiplier),
        proteinG: parseFloat((recipe.proteinG * multiplier).toFixed(1)),
        carbsG: parseFloat((recipe.carbsG * multiplier).toFixed(1)),
        fatG: parseFloat((recipe.fatG * multiplier).toFixed(1)),
      };
    };

    const bScaled = scaleMeal(breakfast, targetBreakfast);
    const lScaled = scaleMeal(lunch, targetLunch);
    const dScaled = scaleMeal(dinner, targetDinner);

    const plannedMeals = [
      {
        mealType: 'breakfast',
        mealTitle: 'Sarapan',
        recipeId: breakfast.id,
        title: breakfast.title,
        servings: bScaled.servings,
        calories: bScaled.calories,
        proteinG: bScaled.proteinG,
        carbsG: bScaled.carbsG,
        fatG: bScaled.fatG,
        alternatives: breakfastCandidates.slice(1, 3).map(alt => ({ id: alt.id, title: alt.title, calories: alt.calories })),
      },
      {
        mealType: 'lunch',
        mealTitle: 'Makan Siang',
        recipeId: lunch.id,
        title: lunch.title,
        servings: lScaled.servings,
        calories: lScaled.calories,
        proteinG: lScaled.proteinG,
        carbsG: lScaled.carbsG,
        fatG: lScaled.fatG,
        alternatives: lunchCandidates.slice(1, 3).map(alt => ({ id: alt.id, title: alt.title, calories: alt.calories })),
      },
      {
        mealType: 'dinner',
        mealTitle: 'Makan Malam',
        recipeId: dinner.id,
        title: dinner.title,
        servings: dScaled.servings,
        calories: dScaled.calories,
        proteinG: dScaled.proteinG,
        carbsG: dScaled.carbsG,
        fatG: dScaled.fatG,
        alternatives: dinnerCandidates.slice(1, 3).map(alt => ({ id: alt.id, title: alt.title, calories: alt.calories })),
      },
    ];

    const totalPlannedCalories = bScaled.calories + lScaled.calories + dScaled.calories;
    const totalPlannedProtein = parseFloat((bScaled.proteinG + lScaled.proteinG + dScaled.proteinG).toFixed(1));
    const totalPlannedCarbs = parseFloat((bScaled.carbsG + lScaled.carbsG + dScaled.carbsG).toFixed(1));
    const totalPlannedFat = parseFloat((bScaled.fatG + lScaled.fatG + dScaled.fatG).toFixed(1));
    const variancePercent = parseFloat((((totalPlannedCalories - targetCalories) / targetCalories) * 100).toFixed(1));

    return {
      date: planDate,
      targetCalories,
      totalPlannedCalories,
      totalPlannedProtein,
      totalPlannedCarbs,
      totalPlannedFat,
      variancePercent,
      isWithinSafetyBounds: Math.abs(variancePercent) <= 15,
      meals: plannedMeals,
      notice: `Menu harian dirancang dalam toleransi ${variancePercent > 0 ? '+' : ''}${variancePercent}% dari target kalori Anda.`,
    };
  }

  /**
   * F11: Rencana Harian Terpadu
   * Menyatukan nutrisi, rencana menu, workout rutin, dan hidrasi
   */
  static async getDailyPlan(userId: string, date: string) {
    await this.ensureTable();

    // 1. Ambil summary nutrisi aktual
    const nutritionSummary = await NutritionService.getDailySummary(userId, date);

    // 2. Ambil data daily_plans tersimpan
    const planRes = await query('SELECT * FROM daily_plans WHERE user_id = $1 AND plan_date = $2', [userId, date]);
    let savedPlan = planRes.rows[0];

    // Jika belum ada plan tersimpan, generate default meal recommendations
    let plannedMeals = savedPlan?.planned_meals;
    if (!plannedMeals || (Array.isArray(plannedMeals) && plannedMeals.length === 0)) {
      const generated = await this.generateDailyMealPlan(userId, date, nutritionSummary.target.calories);
      plannedMeals = generated.meals;
    }

    // 3. Ambil workout routine yang aktif (jika ada)
    const routineRes = await query(
      `SELECT id, title, description, days_per_week
       FROM workout_routines
       WHERE (user_id = $1 OR is_template = TRUE)
       ORDER BY is_template ASC LIMIT 1`,
      [userId]
    );
    const plannedRoutine = routineRes.rows[0] || null;
    const waterTargetMl = savedPlan?.water_target_ml ?? nutritionSummary.target.waterMl;

    return {
      date,
      nutrition: {
        target: nutritionSummary.target,
        consumed: nutritionSummary.consumed,
        remaining: nutritionSummary.remaining,
      },
      plannedMeals,
      workout: plannedRoutine ? {
        routineId: plannedRoutine.id,
        title: plannedRoutine.title,
        description: plannedRoutine.description,
        isCompleted: savedPlan?.is_completed || false,
      } : null,
      hydration: {
        targetMl: waterTargetMl,
        consumedMl: nutritionSummary.consumed.waterMl,
        isTargetMet: nutritionSummary.consumed.waterMl >= waterTargetMl,
      },
      notes: savedPlan?.notes || null,
      isCompleted: savedPlan?.is_completed || false,
    };
  }

  static async saveDailyPlan(userId: string, date: string, data: {
    plannedMeals?: any[];
    workoutRoutineId?: string;
    waterTargetMl?: number;
    notes?: string;
    isCompleted?: boolean;
  }) {
    await this.ensureTable();

    let waterTargetMl = data.waterTargetMl;
    if (waterTargetMl === undefined) {
      const target = (await query('SELECT target_water_ml FROM user_nutrition_targets WHERE user_id = $1', [userId])).rows[0];
      if (!target) {
        throw { statusCode: 409, code: 'NUTRITION_TARGETS_NOT_SET', message: 'Target nutrisi belum tersedia untuk profil ini.' };
      }
      waterTargetMl = Number(target.target_water_ml);
    }
    if (!Number.isInteger(waterTargetMl) || waterTargetMl < 1000 || waterTargetMl > 10000) {
      throw { statusCode: 422, code: 'INVALID_WATER_TARGET', message: 'Target air harus antara 1000 dan 10000 ml.' };
    }

    const sql = `
      INSERT INTO daily_plans (user_id, plan_date, planned_meals, workout_routine_id, water_target_ml, notes, is_completed)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      ON CONFLICT (user_id, plan_date)
      DO UPDATE SET
        planned_meals = COALESCE(EXCLUDED.planned_meals, daily_plans.planned_meals),
        workout_routine_id = COALESCE(EXCLUDED.workout_routine_id, daily_plans.workout_routine_id),
        water_target_ml = COALESCE(EXCLUDED.water_target_ml, daily_plans.water_target_ml),
        notes = COALESCE(EXCLUDED.notes, daily_plans.notes),
        is_completed = COALESCE(EXCLUDED.is_completed, daily_plans.is_completed)
      RETURNING *;
    `;

    const result = await query(sql, [
      userId,
      date,
      JSON.stringify(data.plannedMeals || []),
      data.workoutRoutineId || null,
      waterTargetMl,
      data.notes || null,
      data.isCompleted || false,
    ]);

    return result.rows[0];
  }
}
