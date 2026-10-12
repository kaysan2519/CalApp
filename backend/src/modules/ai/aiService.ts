import { query } from '../../config/db.js';
import { AIProviderFactory } from './providers/aiProvider.js';
import { normalizeUnitToGrams } from './unitConversion.js';
import { NutritionService } from '../nutrition/nutritionService.js';

export class AIService {
  private static provider = AIProviderFactory.getProvider();

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
      let calories = 0;
      let proteinG = 0;
      let carbsG = 0;
      let fatG = 0;

      if (dbFood) {
        const ratio = grams / parseFloat(dbFood.serving_size);
        calories = Math.round(parseFloat(dbFood.calories) * ratio);
        proteinG = parseFloat((parseFloat(dbFood.protein_g) * ratio).toFixed(1));
        carbsG = parseFloat((parseFloat(dbFood.carbs_g) * ratio).toFixed(1));
        fatG = parseFloat((parseFloat(dbFood.fat_g) * ratio).toFixed(1));
      } else {
        // Fallback default calculation based on 100g = ~150 kcal
        calories = Math.round((grams / 100) * 150);
        proteinG = parseFloat(((grams / 100) * 10).toFixed(1));
        carbsG = parseFloat(((grams / 100) * 18).toFixed(1));
        fatG = parseFloat(((grams / 100) * 4).toFixed(1));
      }

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
    if (!text || text.trim().isEmpty) {
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
      let calories = 0;
      let proteinG = 0;
      let carbsG = 0;
      let fatG = 0;

      if (dbFood) {
        const ratio = normalizedGrams / parseFloat(dbFood.serving_size);
        calories = Math.round(parseFloat(dbFood.calories) * ratio);
        proteinG = parseFloat((parseFloat(dbFood.protein_g) * ratio).toFixed(1));
        carbsG = parseFloat((parseFloat(dbFood.carbs_g) * ratio).toFixed(1));
        fatG = parseFloat((parseFloat(dbFood.fat_g) * ratio).toFixed(1));
      } else {
        // Fallback estimate
        calories = Math.round((normalizedGrams / 100) * 140);
        proteinG = parseFloat(((normalizedGrams / 100) * 8).toFixed(1));
        carbsG = parseFloat(((normalizedGrams / 100) * 18).toFixed(1));
        fatG = parseFloat(((normalizedGrams / 100) * 4).toFixed(1));
      }

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
}
