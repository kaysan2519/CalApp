import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { RecipeService } from './recipeService.js';

const logRecipeSchema = z.object({
  mealType: z.enum(['breakfast', 'lunch', 'dinner', 'snack']),
  servings: z.number().positive().default(1),
  logDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal harus YYYY-MM-DD').optional(),
});

export class RecipeController {
  static async getRecipes(req: Request, res: Response, next: NextFunction) {
    try {
      const q = typeof req.query.q === 'string' ? req.query.q : undefined;
      const tag = typeof req.query.tag === 'string' ? req.query.tag : undefined;
      const maxCalories = req.query.maxCalories ? Number(req.query.maxCalories) : undefined;
      const limit = req.query.limit ? Number(req.query.limit) : undefined;
      const offset = req.query.offset ? Number(req.query.offset) : undefined;

      const recipes = await RecipeService.getRecipes({
        query: q,
        tag,
        maxCalories,
        limit,
        offset,
      });

      res.json({
        success: true,
        data: recipes,
      });
    } catch (err) {
      next(err);
    }
  }

  static async getRecipeById(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const servings = req.query.servings ? Number(req.query.servings) : undefined;
      const recipe = await RecipeService.getRecipeById(id, servings);

      res.json({
        success: true,
        data: recipe,
      });
    } catch (err) {
      next(err);
    }
  }

  static async logToMeal(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const { id } = req.params;
      const validated = logRecipeSchema.parse(req.body);

      const result = await RecipeService.logRecipeToMeal(
        userId,
        id,
        validated.mealType,
        validated.servings,
        validated.logDate
      );

      res.status(201).json({
        success: true,
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }
}
