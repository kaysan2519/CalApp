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

  static async refineMealDraft(items: Array<{
    foodItemId?: string | null;
    foodName: string;
    portionDescription?: string;
    estimatedGrams: number;
    calories: number;
    proteinG: number;
    carbsG: number;
    fatG: number;
  }>, instruction: string) {
    if (!instruction || instruction.trim().length === 0) {
      return { items, message: 'Tidak ada instruksi perubahan.' };
    }

    const lower = instruction.toLowerCase().trim();
    const updatedItems = items.map((item) => {
      const copy = { ...item };
      const nameLower = copy.foodName.toLowerCase();

      // Check if this specific item is mentioned or general rule applies
      const isTargetItem = lower.includes(nameLower) ||
        (nameLower.includes('nasi') && lower.includes('nasi')) ||
        (nameLower.includes('ayam') && lower.includes('ayam')) ||
        (nameLower.includes('sayur') && (lower.includes('sayur') || lower.includes('salad'))) ||
        (nameLower.includes('tempe') && lower.includes('tempe'));

      // 1. Half portion modifier
      if ((isTargetItem || items.length === 1) && (lower.includes('setengah') || lower.includes('separuh') || lower.includes('1/2'))) {
        copy.estimatedGrams = Math.round(copy.estimatedGrams * 0.5);
        copy.calories = Math.round(copy.calories * 0.5);
        copy.proteinG = parseFloat((copy.proteinG * 0.5).toFixed(1));
        copy.carbsG = parseFloat((copy.carbsG * 0.5).toFixed(1));
        copy.fatG = parseFloat((copy.fatG * 0.5).toFixed(1));
        copy.portionDescription = `${copy.portionDescription || ''} (1/2 porsi)`.trim();
      }
      // 2. Double portion modifier
      else if ((isTargetItem || items.length === 1) && (lower.includes('dua kali') || lower.includes('double') || lower.includes('2x'))) {
        copy.estimatedGrams = Math.round(copy.estimatedGrams * 2.0);
        copy.calories = Math.round(copy.calories * 2.0);
        copy.proteinG = parseFloat((copy.proteinG * 2.0).toFixed(1));
        copy.carbsG = parseFloat((copy.carbsG * 2.0).toFixed(1));
        copy.fatG = parseFloat((copy.fatG * 2.0).toFixed(1));
      }
      // 3. Skinless chicken modifier
      if (nameLower.includes('ayam') && (lower.includes('tanpa kulit') || lower.includes('skinless') || lower.includes('rebus'))) {
        copy.foodName = copy.foodName.includes('Skinless') ? copy.foodName : `${copy.foodName} (Skinless)`;
        copy.fatG = Math.max(1, parseFloat((copy.fatG * 0.4).toFixed(1)));
        copy.calories = Math.round((copy.proteinG * 4) + (copy.carbsG * 4) + (copy.fatG * 9));
      }
      // 4. Fried / Flour coated modifier
      if (nameLower.includes('ayam') && (lower.includes('tepung') || lower.includes('krispi') || lower.includes('crispy'))) {
        copy.foodName = 'Ayam Goreng Tepung';
        copy.carbsG = parseFloat((copy.carbsG + 14).toFixed(1));
        copy.fatG = parseFloat((copy.fatG + 8).toFixed(1));
        copy.calories = Math.round((copy.proteinG * 4) + (copy.carbsG * 4) + (copy.fatG * 9));
      }
      // 5. Without oil / sauce / dressing
      if (lower.includes('tanpa kuah') || lower.includes('tanpa minyak') || lower.includes('tanpa saus') || lower.includes('tanpa dressing')) {
        if (nameLower.includes('sayur') || nameLower.includes('salad') || nameLower.includes('kuah') || nameLower.includes('gulai')) {
          copy.fatG = Math.max(1, parseFloat((copy.fatG * 0.4).toFixed(1)));
          copy.calories = Math.round((copy.proteinG * 4) + (copy.carbsG * 4) + (copy.fatG * 9));
        }
      }

      // 6. Explicit gram modifier: e.g. "150g" or "200 gram"
      const gramMatch = lower.match(/(\d+)\s*(?:g|gram)/);
      if (gramMatch && (isTargetItem || items.length === 1)) {
        const targetGrams = parseInt(gramMatch[1], 10);
        if (targetGrams > 0 && copy.estimatedGrams > 0) {
          const ratio = targetGrams / copy.estimatedGrams;
          copy.estimatedGrams = targetGrams;
          copy.calories = Math.round(copy.calories * ratio);
          copy.proteinG = parseFloat((copy.proteinG * ratio).toFixed(1));
          copy.carbsG = parseFloat((copy.carbsG * ratio).toFixed(1));
          copy.fatG = parseFloat((copy.fatG * ratio).toFixed(1));
        }
      }

      return copy;
    });

    return {
      items: updatedItems,
      message: `Porsi berhasil disesuaikan dengan instruksi: "${instruction}".`,
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
