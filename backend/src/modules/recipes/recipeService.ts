import { query } from '../../config/db.js';
import { NutritionService } from '../nutrition/nutritionService.js';

export interface RecipeFilter {
  query?: string;
  tag?: string;
  maxCalories?: number;
  limit?: number;
  offset?: number;
}

export class RecipeService {
  static async getRecipes(filter: RecipeFilter = {}) {
    const conditions: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (filter.query && filter.query.trim()) {
      conditions.push(`(LOWER(title) LIKE $${idx} OR LOWER(description) LIKE $${idx})`);
      values.push(`%${filter.query.toLowerCase()}%`);
      idx++;
    }

    if (filter.tag && filter.tag.trim()) {
      conditions.push(`$${idx} = ANY(dietary_tags)`);
      values.push(filter.tag.trim());
      idx++;
    }

    if (filter.maxCalories && filter.maxCalories > 0) {
      conditions.push(`calories_per_serving <= $${idx}`);
      values.push(filter.maxCalories);
      idx++;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const limit = filter.limit || 50;
    const offset = filter.offset || 0;

    const sql = `
      SELECT id, title, description, image_url, prep_time_min, cook_time_min,
             servings, calories_per_serving, protein_per_serving, carbs_per_serving, fat_per_serving,
             dietary_tags, ingredients, instructions, created_at
      FROM recipes
      ${whereClause}
      ORDER BY title ASC
      LIMIT $${idx} OFFSET $${idx + 1}
    `;
    values.push(limit, offset);

    const result = await query(sql, values);
    return result.rows;
  }

  static async getRecipeById(id: string, requestedServings?: number) {
    const result = await query('SELECT * FROM recipes WHERE id = $1', [id]);
    if (result.rows.length === 0) {
      throw { statusCode: 404, code: 'RECIPE_NOT_FOUND', message: 'Resep tidak ditemukan.' };
    }

    const recipe = result.rows[0];
    const baseServings = parseInt(recipe.servings) || 1;
    const targetServings = requestedServings && requestedServings > 0 ? requestedServings : baseServings;
    const scaleRatio = targetServings / baseServings;

    const scaledCalories = Math.round(parseFloat(recipe.calories_per_serving) * targetServings);
    const scaledProtein = parseFloat((parseFloat(recipe.protein_per_serving) * targetServings).toFixed(1));
    const scaledCarbs = parseFloat((parseFloat(recipe.carbs_per_serving) * targetServings).toFixed(1));
    const scaledFat = parseFloat((parseFloat(recipe.fat_per_serving) * targetServings).toFixed(1));

    const rawIngredients = Array.isArray(recipe.ingredients) ? recipe.ingredients : [];
    const scaledIngredients = rawIngredients.map((ing: any) => ({
      ...ing,
      qty: ing.qty != null ? parseFloat((ing.qty * scaleRatio).toFixed(1)) : null,
    }));

    return {
      ...recipe,
      baseServings,
      servings: targetServings,
      calories_per_serving: parseFloat(recipe.calories_per_serving),
      protein_per_serving: parseFloat(recipe.protein_per_serving),
      carbs_per_serving: parseFloat(recipe.carbs_per_serving),
      fat_per_serving: parseFloat(recipe.fat_per_serving),
      totalCalories: scaledCalories,
      totalProteinG: scaledProtein,
      totalCarbsG: scaledCarbs,
      totalFatG: scaledFat,
      ingredients: scaledIngredients,
    };
  }

  static async logRecipeToMeal(
    userId: string,
    recipeId: string,
    mealType: 'breakfast' | 'lunch' | 'dinner' | 'snack',
    servings: number = 1,
    logDate?: string,
  ) {
    const date = logDate || new Date().toISOString().split('T')[0];
    const recipe = await this.getRecipeById(recipeId, servings);

    const mealItem = await NutritionService.logMealItem(userId, {
      logDate: date,
      mealType,
      foodName: recipe.title,
      servingQty: servings,
      servingUnit: 'porsi',
      calories: recipe.totalCalories,
      proteinG: recipe.totalProteinG,
      carbsG: recipe.totalCarbsG,
      fatG: recipe.totalFatG,
      source: 'recipe',
    });

    return {
      mealItem,
      recipeTitle: recipe.title,
      loggedServings: servings,
    };
  }
}
