import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { NutritionService } from './nutritionService.js';

const logMealItemSchema = z.object({
  logDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal harus YYYY-MM-DD'),
  mealType: z.enum(['breakfast', 'lunch', 'dinner', 'snack']),
  foodItemId: z.string().uuid().optional(),
  foodName: z.string().min(1, 'Nama makanan wajib diisi'),
  servingQty: z.number().positive('Jumlah sajian harus positif'),
  servingUnit: z.string().min(1, 'Satuan sajian wajib diisi'),
  calories: z.number().nonnegative('Kalori tidak boleh negatif'),
  proteinG: z.number().nonnegative(),
  carbsG: z.number().nonnegative(),
  fatG: z.number().nonnegative(),
  source: z.string().optional(),
  confidenceScore: z.number().optional(),
  snapshotData: z.any().optional(),
});

const updateMealItemSchema = z.object({
  servingQty: z.number().positive('Jumlah sajian harus positif'),
});

const createCustomFoodSchema = z.object({
  name: z.string().min(2, 'Nama makanan minimal 2 karakter'),
  nameId: z.string().optional(),
  brand: z.string().optional(),
  barcode: z.string().optional(),
  servingSize: z.number().positive(),
  servingUnit: z.string().min(1),
  calories: z.number().nonnegative(),
  proteinG: z.number().nonnegative(),
  carbsG: z.number().nonnegative(),
  fatG: z.number().nonnegative(),
  fiberG: z.number().optional(),
});

const logWaterSchema = z.object({
  logDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal harus YYYY-MM-DD'),
  amountMl: z.number().int().positive().max(5000),
});

export class NutritionController {
  static async searchFoods(req: Request, res: Response, next: NextFunction) {
    try {
      const q = req.query.q as string | undefined;
      const barcode = req.query.barcode as string | undefined;
      const userId = req.user?.id;

      const foods = await NutritionService.searchFoods(q, barcode, userId);
      res.json({
        success: true,
        data: foods,
      });
    } catch (err) {
      next(err);
    }
  }

  static async getProductByBarcode(req: Request, res: Response, next: NextFunction) {
    try {
      const barcode = req.params.barcode;
      const foods = await NutritionService.searchFoods(undefined, barcode);
      if (foods.length === 0) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'PRODUCT_NOT_FOUND',
            message: 'Produk tidak ditemukan di database atau Open Food Facts. Anda dapat memasukkannya secara manual.',
          },
        });
      }
      res.json({
        success: true,
        data: foods[0],
      });
    } catch (err) {
      next(err);
    }
  }

  static async createCustomFood(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const validated = createCustomFoodSchema.parse(req.body);
      const food = await NutritionService.createCustomFood(userId, validated);
      res.status(201).json({
        success: true,
        data: food,
        message: 'Makanan kustom berhasil disimpan.',
      });
    } catch (err) {
      next(err);
    }
  }

  static async getDailySummary(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const date = (req.query.date as string) || new Date().toISOString().split('T')[0];
      const summary = await NutritionService.getDailySummary(userId, date);
      res.json({
        success: true,
        data: summary,
      });
    } catch (err) {
      next(err);
    }
  }

  static async logMealItem(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const validated = logMealItemSchema.parse(req.body);
      const item = await NutritionService.logMealItem(userId, validated);
      res.status(201).json({
        success: true,
        data: item,
        message: 'Makanan berhasil dicatat.',
      });
    } catch (err) {
      next(err);
    }
  }

  static async updateMealItem(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const itemId = req.params.itemId;
      const validated = updateMealItemSchema.parse(req.body);
      const item = await NutritionService.updateMealItem(userId, itemId, validated.servingQty);
      res.json({
        success: true,
        data: item,
        message: 'Jumlah makanan berhasil diperbarui.',
      });
    } catch (err) {
      next(err);
    }
  }

  static async deleteMealItem(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const itemId = req.params.itemId;
      await NutritionService.deleteMealItem(userId, itemId);
      res.json({
        success: true,
        message: 'Item makanan berhasil dihapus.',
      });
    } catch (err) {
      next(err);
    }
  }

  static async logWater(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const validated = logWaterSchema.parse(req.body);
      const result = await NutritionService.logWater(userId, validated.logDate, validated.amountMl);
      res.status(201).json({
        success: true,
        data: result,
        message: 'Konsumsi air berhasil dicatat.',
      });
    } catch (err) {
      next(err);
    }
  }

  static async getWeeklySummary(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const startDate = (req.query.startDate as string) || new Date().toISOString().split('T')[0];
      const result = await NutritionService.getWeeklySummary(userId, startDate);
      res.json({
        success: true,
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }
}
