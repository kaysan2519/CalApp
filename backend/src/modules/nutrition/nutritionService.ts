import { query } from '../../config/db.js';
import { gamificationService } from '../gamification/gamificationService.js';

export interface CreateFoodDTO {
  name: string;
  nameId?: string;
  brand?: string;
  barcode?: string;
  servingSize: number;
  servingUnit: string;
  calories: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
  fiberG?: number;
}

export interface LogMealItemDTO {
  logDate: string; // YYYY-MM-DD
  mealType: 'breakfast' | 'lunch' | 'dinner' | 'snack';
  foodItemId?: string;
  foodName: string;
  servingQty: number;
  servingUnit: string;
  calories: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
  source?: string;
  confidenceScore?: number;
  snapshotData?: any;
}

export class NutritionService {
  static async searchFoods(searchTerm?: string, barcode?: string, userId?: string) {
    if (barcode) {
      // 1. Search in local catalog first
      const localRes = await query('SELECT * FROM food_items WHERE barcode = $1', [barcode]);
      if (localRes.rows.length > 0) {
        return localRes.rows;
      }

      // 2. Query Open Food Facts API with respectful User-Agent and cache
      try {
        const offProduct = await this.fetchOpenFoodFacts(barcode);
        if (offProduct) {
          // Cache in local DB
          const insertRes = await query(
            `INSERT INTO food_items (name, name_id, brand, barcode, serving_size, serving_unit, calories, protein_g, carbs_g, fat_g, fiber_g, source, license, is_verified)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'open_food_facts', 'ODbL Open Food Facts', TRUE)
             ON CONFLICT (barcode) DO UPDATE SET updated_at = NOW()
             RETURNING *`,
            [
              offProduct.name,
              offProduct.nameId,
              offProduct.brand,
              offProduct.barcode,
              offProduct.servingSize,
              offProduct.servingUnit,
              offProduct.calories,
              offProduct.proteinG,
              offProduct.carbsG,
              offProduct.fatG,
              offProduct.fiberG,
            ]
          );
          return insertRes.rows;
        }
      } catch (err) {
        console.warn(`[OpenFoodFacts] Offline or lookup failed for barcode ${barcode}:`, err);
      }

      return [];
    }

    if (!searchTerm || searchTerm.trim().length === 0) {
      // Return top Indonesian staples
      const topRes = await query('SELECT * FROM food_items ORDER BY is_verified DESC, name ASC LIMIT 20');
      return topRes.rows;
    }

    const term = `%${searchTerm.trim().toLowerCase()}%`;
    const searchRes = await query(
      `SELECT * FROM food_items
       WHERE LOWER(name) LIKE $1 OR LOWER(name_id) LIKE $1 OR LOWER(brand) LIKE $1
       ORDER BY 
         CASE WHEN LOWER(name_id) LIKE $1 THEN 1 ELSE 2 END,
         is_verified DESC,
         name ASC
       LIMIT 30`,
      [term]
    );

    return searchRes.rows;
  }

  static async fetchOpenFoodFacts(barcode: string) {
    if (process.env.NODE_ENV === 'test') {
      return null;
    }
    const url = `https://world.openfoodfacts.org/api/v2/product/${encodeURIComponent(barcode)}.json`;
    const response = await fetch(url, {
      signal: AbortSignal.timeout(2500),
      headers: {
        'User-Agent': 'CalApp - Android/iOS - Version 1.0 (https://github.com/kaysan2519/CalApp; contact@example.com)',
      },
    });

    if (!response.ok) return null;
    const json = await response.json();
    if (json.status !== 1 || !json.product) return null;

    const p = json.product;
    const nutriments = p.nutriments || {};

    const calories = nutriments['energy-kcal_100g'] ?? (nutriments['energy_100g'] ? Math.round(nutriments['energy_100g'] / 4.184) : 0);
    const protein = nutriments.proteins_100g ?? 0;
    const carbs = nutriments.carbohydrates_100g ?? 0;
    const fat = nutriments.fat_100g ?? 0;
    const fiber = nutriments.fiber_100g ?? 0;

    return {
      barcode,
      name: p.product_name || p.product_name_en || 'Unknown Product',
      nameId: p.product_name_id || p.product_name || 'Produk Barcode',
      brand: p.brands || 'Open Food Facts',
      servingSize: 100,
      servingUnit: 'gram',
      calories: Math.round(calories),
      proteinG: parseFloat(protein.toFixed(2)),
      carbsG: parseFloat(carbs.toFixed(2)),
      fatG: parseFloat(fat.toFixed(2)),
      fiberG: parseFloat(fiber.toFixed(2)),
    };
  }

  static async createCustomFood(userId: string, data: CreateFoodDTO) {
    const res = await query(
      `INSERT INTO food_items (name, name_id, brand, barcode, serving_size, serving_unit, calories, protein_g, carbs_g, fat_g, fiber_g, source, license, is_verified, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'custom_user', 'User Created', FALSE, $12)
       RETURNING *`,
      [
        data.name,
        data.nameId || data.name,
        data.brand || null,
        data.barcode || null,
        data.servingSize,
        data.servingUnit,
        data.calories,
        data.proteinG,
        data.carbsG,
        data.fatG,
        data.fiberG || 0,
        userId,
      ]
    );
    return res.rows[0];
  }

  static async getDailySummary(userId: string, logDate: string) {
    // 1. Get User Nutrition Target
    const targetRes = await query('SELECT * FROM user_nutrition_targets WHERE user_id = $1', [userId]);
    const target = targetRes.rows[0];
    if (!target) {
      throw { statusCode: 409, code: 'NUTRITION_TARGETS_UNAVAILABLE', message: 'Target nutrisi belum tersedia. Lengkapi profil terlebih dahulu.' };
    }

    // 2. Fetch Meal Logs and their items for that date
    const mealLogsRes = await query(
      `SELECT ml.id as meal_log_id, ml.meal_type,
              mi.id as item_id, mi.food_item_id, mi.food_name, mi.serving_qty, mi.serving_unit,
              mi.calories, mi.protein_g, mi.carbs_g, mi.fat_g, mi.source, mi.created_at
       FROM meal_logs ml
       LEFT JOIN meal_log_items mi ON ml.id = mi.meal_log_id
       WHERE ml.user_id = $1 AND ml.log_date = $2
       ORDER BY mi.created_at ASC`,
      [userId, logDate]
    );

    // Group by meal slot
    const meals: Record<string, { mealLogId: string | null; items: any[]; totalCalories: number }> = {
      breakfast: { mealLogId: null, items: [], totalCalories: 0 },
      lunch: { mealLogId: null, items: [], totalCalories: 0 },
      dinner: { mealLogId: null, items: [], totalCalories: 0 },
      snack: { mealLogId: null, items: [], totalCalories: 0 },
    };

    let totalConsumedCalories = 0;
    let totalConsumedProtein = 0;
    let totalConsumedCarbs = 0;
    let totalConsumedFat = 0;

    for (const row of mealLogsRes.rows) {
      const type = row.meal_type;
      if (meals[type]) {
        meals[type].mealLogId = row.meal_log_id;
        if (row.item_id) {
          const item = {
            id: row.item_id,
            foodItemId: row.food_item_id,
            foodName: row.food_name,
            servingQty: parseFloat(row.serving_qty),
            servingUnit: row.serving_unit,
            calories: parseFloat(row.calories),
            proteinG: parseFloat(row.protein_g),
            carbsG: parseFloat(row.carbs_g),
            fatG: parseFloat(row.fat_g),
            source: row.source,
            createdAt: row.created_at,
          };
          meals[type].items.push(item);
          meals[type].totalCalories += item.calories;

          totalConsumedCalories += item.calories;
          totalConsumedProtein += item.proteinG;
          totalConsumedCarbs += item.carbsG;
          totalConsumedFat += item.fatG;
        }
      }
    }

    // 3. Water Intake
    const waterRes = await query(
      'SELECT COALESCE(SUM(amount_ml), 0) as total_water FROM water_logs WHERE user_id = $1 AND log_date = $2',
      [userId, logDate]
    );
    const totalWaterMl = parseInt(waterRes.rows[0].total_water, 10);

    const targetCal = target.target_calories;
    const remainingCalories = Math.max(0, targetCal - totalConsumedCalories);

    return {
      logDate,
      target: {
        calories: targetCal,
        proteinG: parseFloat(target.target_protein_g),
        carbsG: parseFloat(target.target_carbs_g),
        fatG: parseFloat(target.target_fat_g),
        waterMl: target.target_water_ml,
      },
      consumed: {
        calories: Math.round(totalConsumedCalories),
        proteinG: parseFloat(totalConsumedProtein.toFixed(1)),
        carbsG: parseFloat(totalConsumedCarbs.toFixed(1)),
        fatG: parseFloat(totalConsumedFat.toFixed(1)),
        waterMl: totalWaterMl,
      },
      remaining: {
        calories: Math.round(remainingCalories),
        proteinG: parseFloat(Math.max(0, target.target_protein_g - totalConsumedProtein).toFixed(1)),
        carbsG: parseFloat(Math.max(0, target.target_carbs_g - totalConsumedCarbs).toFixed(1)),
        fatG: parseFloat(Math.max(0, target.target_fat_g - totalConsumedFat).toFixed(1)),
        waterMl: Math.max(0, target.target_water_ml - totalWaterMl),
      },
      meals,
    };
  }

  static async logMealItem(userId: string, data: LogMealItemDTO) {
    // 1. Get or create meal_log slot
    let mealLogRes = await query(
      'SELECT id FROM meal_logs WHERE user_id = $1 AND log_date = $2 AND meal_type = $3',
      [userId, data.logDate, data.mealType]
    );

    let mealLogId: string;
    if (mealLogRes.rows.length === 0) {
      const newMeal = await query(
        'INSERT INTO meal_logs (user_id, log_date, meal_type) VALUES ($1, $2, $3) RETURNING id',
        [userId, data.logDate, data.mealType]
      );
      mealLogId = newMeal.rows[0].id;
    } else {
      mealLogId = mealLogRes.rows[0].id;
    }

    // 2. Snapshot values and store item
    const snapshot = data.snapshotData || {
      loggedAt: new Date().toISOString(),
      rawCalories: data.calories,
      rawProtein: data.proteinG,
      rawCarbs: data.carbsG,
      rawFat: data.fatG,
    };

    const itemRes = await query(
      `INSERT INTO meal_log_items (meal_log_id, food_item_id, food_name, serving_qty, serving_unit, calories, protein_g, carbs_g, fat_g, source, confidence_score, snapshot_data)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
       RETURNING *`,
      [
        mealLogId,
        data.foodItemId || null,
        data.foodName,
        data.servingQty,
        data.servingUnit,
        data.calories,
        data.proteinG,
        data.carbsG,
        data.fatG,
        data.source || 'database',
        data.confidenceScore || null,
        JSON.stringify(snapshot),
      ]
    );

    // Update meal_logs updated_at timestamp
    await query('UPDATE meal_logs SET updated_at = NOW() WHERE id = $1', [mealLogId]);

    let xpReward = null;
    try {
      xpReward = await gamificationService.awardActivityXp(userId, 'meal_logged', mealLogId);
    } catch {
      // The food log remains saved if XP storage is temporarily unavailable.
    }
    return { ...itemRes.rows[0], xpReward };
  }

  static async updateMealItem(userId: string, itemId: string, servingQty: number) {
    // Verify ownership through meal_logs
    const itemCheck = await query(
      `SELECT mi.*, ml.user_id, ml.id as meal_log_id
       FROM meal_log_items mi
       JOIN meal_logs ml ON mi.meal_log_id = ml.id
       WHERE mi.id = $1 AND ml.user_id = $2`,
      [itemId, userId]
    );

    if (itemCheck.rows.length === 0) {
      throw { statusCode: 404, code: 'ITEM_NOT_FOUND', message: 'Item catatan makanan tidak ditemukan.' };
    }

    const currentItem = itemCheck.rows[0];
    const prevQty = parseFloat(currentItem.serving_qty);
    const ratio = servingQty / (prevQty > 0 ? prevQty : 1);

    const newCalories = Math.round(parseFloat(currentItem.calories) * ratio);
    const newProtein = parseFloat((parseFloat(currentItem.protein_g) * ratio).toFixed(2));
    const newCarbs = parseFloat((parseFloat(currentItem.carbs_g) * ratio).toFixed(2));
    const newFat = parseFloat((parseFloat(currentItem.fat_g) * ratio).toFixed(2));

    const updated = await query(
      `UPDATE meal_log_items
       SET serving_qty = $1, calories = $2, protein_g = $3, carbs_g = $4, fat_g = $5
       WHERE id = $6
       RETURNING *`,
      [servingQty, newCalories, newProtein, newCarbs, newFat, itemId]
    );

    await query('UPDATE meal_logs SET updated_at = NOW() WHERE id = $1', [currentItem.meal_log_id]);

    return updated.rows[0];
  }

  static async deleteMealItem(userId: string, itemId: string) {
    const itemCheck = await query(
      `SELECT mi.id, ml.id as meal_log_id
       FROM meal_log_items mi
       JOIN meal_logs ml ON mi.meal_log_id = ml.id
       WHERE mi.id = $1 AND ml.user_id = $2`,
      [itemId, userId]
    );

    if (itemCheck.rows.length === 0) {
      throw { statusCode: 404, code: 'ITEM_NOT_FOUND', message: 'Item catatan makanan tidak ditemukan.' };
    }

    await query('DELETE FROM meal_log_items WHERE id = $1', [itemId]);
    await query('UPDATE meal_logs SET updated_at = NOW() WHERE id = $1', [itemCheck.rows[0].meal_log_id]);

    return { deleted: true };
  }

  static async logWater(userId: string, logDate: string, amountMl: number) {
    if (amountMl <= 0 || amountMl > 5000) {
      throw { statusCode: 422, code: 'INVALID_WATER_AMOUNT', message: 'Jumlah air tidak valid.' };
    }

    await query(
      'INSERT INTO water_logs (user_id, log_date, amount_ml) VALUES ($1, $2, $3)',
      [userId, logDate, amountMl]
    );

    const totalRes = await query(
      'SELECT COALESCE(SUM(amount_ml), 0) as total FROM water_logs WHERE user_id = $1 AND log_date = $2',
      [userId, logDate]
    );

    return {
      logDate,
      addedMl: amountMl,
      totalWaterMl: parseInt(totalRes.rows[0].total, 10),
    };
  }

  static async getWeeklySummary(userId: string, startDate: string) {
    // 7 days window: startDate to startDate + 6 days
    const res = await query(
      `SELECT ml.log_date,
              COALESCE(SUM(mi.calories), 0) as day_calories,
              COALESCE(SUM(mi.protein_g), 0) as day_protein,
              COALESCE(SUM(mi.carbs_g), 0) as day_carbs,
              COALESCE(SUM(mi.fat_g), 0) as day_fat
       FROM meal_logs ml
       LEFT JOIN meal_log_items mi ON ml.id = mi.meal_log_id
       WHERE ml.user_id = $1 
         AND ml.log_date >= $2::DATE 
         AND ml.log_date <= ($2::DATE + INTERVAL '6 days')
       GROUP BY ml.log_date
       ORDER BY ml.log_date ASC`,
      [userId, startDate]
    );

    const loggedDays = res.rows.length;
    let totalCalories = 0;
    let totalProtein = 0;
    let totalCarbs = 0;
    let totalFat = 0;

    for (const day of res.rows) {
      totalCalories += parseFloat(day.day_calories);
      totalProtein += parseFloat(day.day_protein);
      totalCarbs += parseFloat(day.day_carbs);
      totalFat += parseFloat(day.day_fat);
    }

    const avgCalories = loggedDays > 0 ? Math.round(totalCalories / loggedDays) : 0;
    const avgProtein = loggedDays > 0 ? parseFloat((totalProtein / loggedDays).toFixed(1)) : 0;
    const avgCarbs = loggedDays > 0 ? parseFloat((totalCarbs / loggedDays).toFixed(1)) : 0;
    const avgFat = loggedDays > 0 ? parseFloat((totalFat / loggedDays).toFixed(1)) : 0;

    return {
      startDate,
      loggedDaysCount: loggedDays,
      averages: {
        dailyCalories: avgCalories,
        dailyProteinG: avgProtein,
        dailyCarbsG: avgCarbs,
        dailyFatG: avgFat,
      },
      dailyRecords: res.rows.map(r => ({
        date: r.log_date,
        calories: Math.round(parseFloat(r.day_calories)),
        proteinG: parseFloat(r.day_protein),
        carbsG: parseFloat(r.day_carbs),
        fatG: parseFloat(r.day_fat),
      })),
    };
  }
}
