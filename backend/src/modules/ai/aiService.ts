import { query } from '../../config/db.js';
import { ProfileRecommendations } from './providers/aiProvider.js';
import { AIProviderFactory } from './providers/aiProvider.js';
import { normalizeUnitToGrams } from './unitConversion.js';
import { NutritionService } from '../nutrition/nutritionService.js';

export class AIService {
  private static get provider() {
    return AIProviderFactory.getProvider();
  }

  static async analyzeFoodVision(base64Image: string) {
    const rawResult = await this.provider.analyzeFoodImage(base64Image);

    if (!rawResult.isFood) {
      return {
        isFood: false,
        nonFoodReason: rawResult.nonFoodReason || 'Gambar bukan makanan.',
        draftItems: [],
      };
    }

    // Resolve each detected item against database food catalog
    const draftItems = [];
    for (const item of rawResult.detectedItems) {
      // Find matching food in DB
      const searchRes = await query(
        `SELECT * FROM food_items
         WHERE LOWER(name) LIKE $1 OR LOWER(name_id) LIKE $1
         ORDER BY is_verified DESC LIMIT 1`,
        [`%${item.label.toLowerCase()}%`]
      );

      const dbFood = searchRes.rows[0];
      const grams = item.estimatedGrams;
      if (!dbFood) {
        throw { statusCode: 422, code: 'AI_FOOD_NOT_IN_CATALOG', message: `Data nutrisi terverifikasi untuk "${item.label}" belum tersedia. Pilih makanan dari katalog atau masukkan secara manual.` };
      }
      const ratio = grams / parseFloat(dbFood.serving_size);
      const calories = Math.round(parseFloat(dbFood.calories) * ratio);
      const proteinG = parseFloat((parseFloat(dbFood.protein_g) * ratio).toFixed(1));
      const carbsG = parseFloat((parseFloat(dbFood.carbs_g) * ratio).toFixed(1));
      const fatG = parseFloat((parseFloat(dbFood.fat_g) * ratio).toFixed(1));

      draftItems.push({
        foodItemId: dbFood?.id || null,
        foodName: dbFood?.name_id || dbFood?.name || item.label,
        portionDescription: item.estimatedPortionDescription,
        estimatedGrams: grams,
        calories,
        proteinG,
        carbsG,
        fatG,
        confidenceScore: item.confidenceScore,
        source: 'ai_estimate',
        isAiEstimate: true,
      });
    }

    return {
      isFood: true,
      draftItems,
      notice: 'Nilai gizi dari foto merupakan estimasi AI. Silakan periksa dan sesuaikan porsi sebelum menyimpan.',
    };
  }

  static async parseFoodText(text: string) {
    if (!text || text.trim().length === 0) {
      throw { statusCode: 422, code: 'EMPTY_TEXT', message: 'Teks makanan tidak boleh kosong.' };
    }

    const entities = await this.provider.extractFoodEntities(text);
    const resolvedItems = [];

    for (const entity of entities) {
      const { normalizedGrams, standardUnit } = normalizeUnitToGrams(entity.rawUnit, entity.quantity);

      // Search matching food in database
      const searchRes = await query(
        `SELECT * FROM food_items
         WHERE LOWER(name) LIKE $1 OR LOWER(name_id) LIKE $1
         ORDER BY is_verified DESC LIMIT 1`,
        [`%${entity.foodName.toLowerCase()}%`]
      );

      const dbFood = searchRes.rows[0];
      if (!dbFood) {
        throw { statusCode: 422, code: 'AI_FOOD_NOT_IN_CATALOG', message: `Data nutrisi terverifikasi untuk "${entity.foodName}" belum tersedia. Pilih makanan dari katalog atau masukkan secara manual.` };
      }
      const ratio = normalizedGrams / parseFloat(dbFood.serving_size);
      const calories = Math.round(parseFloat(dbFood.calories) * ratio);
      const proteinG = parseFloat((parseFloat(dbFood.protein_g) * ratio).toFixed(1));
      const carbsG = parseFloat((parseFloat(dbFood.carbs_g) * ratio).toFixed(1));
      const fatG = parseFloat((parseFloat(dbFood.fat_g) * ratio).toFixed(1));

      resolvedItems.push({
        foodItemId: dbFood?.id || null,
        foodName: dbFood?.name_id || dbFood?.name || entity.foodName,
        quantity: entity.quantity,
        rawUnit: entity.rawUnit,
        normalizedGrams,
        standardUnit,
        calories,
        proteinG,
        carbsG,
        fatG,
        source: 'ai_text_parsed',
      });
    }

    return {
      originalText: text,
      parsedItems: resolvedItems,
      notice: 'Item dan porsi dinormalkan ke gram berdasarkan tabel konversi pangan. Periksa sebelum disimpan.',
    };
  }

  static async coachChat(userId: string, userMessage: string) {
    // 1. Fetch authorized user data from database (Tool Calling)
    const userRes = await query('SELECT name, goal FROM users WHERE id = $1', [userId]);
    const user = userRes.rows[0] || { name: 'Pengguna', goal: 'maintain' };

    const today = new Date().toISOString().split('T')[0];
    const dailySummary = await NutritionService.getDailySummary(userId, today);

    const context = {
      userName: user.name,
      goal: user.goal,
      targetCalories: dailySummary.target.calories,
      targetProteinG: dailySummary.target.proteinG,
      targetCarbsG: dailySummary.target.carbsG,
      targetFatG: dailySummary.target.fatG,
      consumedCalories: dailySummary.consumed.calories,
      consumedProteinG: dailySummary.consumed.proteinG,
      consumedCarbsG: dailySummary.consumed.carbsG,
      consumedFatG: dailySummary.consumed.fatG,
      consumedWaterMl: dailySummary.consumed.waterMl,
      mealsSummary: `Sarapan: ${dailySummary.meals.breakfast.totalCalories} kkal, Makan Siang: ${dailySummary.meals.lunch.totalCalories} kkal, Makan Malam: ${dailySummary.meals.dinner.totalCalories} kkal`,
    };

    // 2. Generate Coach response
    const reply = await this.provider.generateCoachResponse(context, userMessage);

    return {
      message: reply,
      disclaimer: 'Peringatan: Saran AI Coach hanya untuk panduan gaya hidup sehat dan bukan pengganti konsultasi medis profesional.',
      contextSnapshot: {
        consumedCalories: dailySummary.consumed.calories,
        remainingCalories: dailySummary.remaining.calories,
      },
    };
  }

  static async generateWorkout(goal: string, daysPerWeek: number, equipment: string) {
    return await this.provider.generateWorkoutPlan(goal, daysPerWeek, equipment);
  }

  static async generateProfileRecommendations(userId: string) {
    const profileResult = await query(
      `SELECT name, age, gender, height_cm, weight_kg, target_weight_kg, activity_level, goal,
              training_experience, training_days_per_week, training_schedule, available_equipment,
              food_preferences, allergies, dietary_restrictions, activity_limitations,
              onboarding_completed, timezone
       FROM users WHERE id = $1`,
      [userId],
    );
    const profile = profileResult.rows[0];
    if (!profile) throw { statusCode: 404, code: 'USER_NOT_FOUND', message: 'Profil pengguna tidak ditemukan.' };
    if (!profile.onboarding_completed) {
      throw { statusCode: 409, code: 'ONBOARDING_INCOMPLETE', message: 'Lengkapi profil sebelum membuat rekomendasi.' };
    }

    const targetResult = await query('SELECT * FROM user_nutrition_targets WHERE user_id = $1', [userId]);
    const targets = targetResult.rows[0];
    if (!targets) {
      throw { statusCode: 409, code: 'NUTRITION_TARGETS_UNAVAILABLE', message: 'Target nutrisi belum tersedia untuk profil ini.' };
    }
    const activityResult = await query(
      `SELECT title, started_at, completed_at, duration_seconds
       FROM workout_sessions WHERE user_id = $1 AND status = 'completed'
       ORDER BY completed_at DESC NULLS LAST LIMIT 5`,
      [userId],
    );
    const nutrition = await NutritionService.getDailySummary(userId, this.getLocalDate(profile.timezone));

    const context = {
      profile: {
        age: Number(profile.age),
        gender: profile.gender,
        heightCm: Number(profile.height_cm),
        weightKg: Number(profile.weight_kg),
        targetWeightKg: profile.target_weight_kg == null ? null : Number(profile.target_weight_kg),
        goal: profile.goal,
        activityLevel: profile.activity_level,
        trainingExperience: profile.training_experience,
        trainingDaysPerWeek: Number(profile.training_days_per_week),
        trainingSchedule: profile.training_schedule,
        availableEquipment: profile.available_equipment,
        foodPreferences: profile.food_preferences,
        allergies: profile.allergies,
        dietaryRestrictions: profile.dietary_restrictions,
        activityLimitations: profile.activity_limitations,
      },
      deterministicNutritionTargets: {
        calories: Number(targets.target_calories),
        proteinG: Number(targets.target_protein_g),
        carbsG: Number(targets.target_carbs_g),
        fatG: Number(targets.target_fat_g),
        waterMl: Number(targets.target_water_ml),
      },
      recordedActivity: activityResult.rows.map(activity => ({
        title: activity.title,
        completedAt: activity.completed_at,
        durationSeconds: activity.duration_seconds,
      })),
      todayRecordedNutrition: {
        consumedCalories: nutrition.consumed.calories,
        consumedProteinG: nutrition.consumed.proteinG,
        consumedCarbsG: nutrition.consumed.carbsG,
        consumedFatG: nutrition.consumed.fatG,
      },
    };

    const recommendations: ProfileRecommendations = await this.provider.generateProfileRecommendations(context);
    return {
      nutritionTargets: {
        targetCalories: Number(targets.target_calories),
        targetProteinG: Number(targets.target_protein_g),
        targetCarbsG: Number(targets.target_carbs_g),
        targetFatG: Number(targets.target_fat_g),
        targetWaterMl: Number(targets.target_water_ml),
        isManual: targets.is_manual,
      },
      recommendations,
      generatedAt: new Date().toISOString(),
      notice: 'Target nutrisi dihitung oleh Cal dari data profil. Saran menu dan latihan adalah estimasi AI yang dapat ditinjau dan disesuaikan.',
    };
  }

  private static getLocalDate(timezone: string): string {
    const parts = new Intl.DateTimeFormat('en-CA', {
      timeZone: timezone || 'Asia/Jakarta', year: 'numeric', month: '2-digit', day: '2-digit',
    }).formatToParts(new Date());
    const part = (type: string) => parts.find(value => value.type === type)?.value ?? '';
    return `${part('year')}-${part('month')}-${part('day')}`;
  }
}
