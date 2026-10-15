import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { PlannerService } from './plannerService.js';

const generatorSchema = z.object({
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal harus YYYY-MM-DD').optional(),
  targetCalories: z.number().int().min(1000).max(5000).optional(),
});

const savePlanSchema = z.object({
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal harus YYYY-MM-DD'),
  plannedMeals: z.array(z.any()).optional(),
  workoutRoutineId: z.string().uuid().optional(),
  waterTargetMl: z.number().int().min(1000).max(10000).optional(),
  notes: z.string().optional(),
  isCompleted: z.boolean().optional(),
});

export class PlannerController {
  static async generateMenu(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const validated = generatorSchema.parse(req.body);
      const plan = await PlannerService.generateDailyMealPlan(
        userId,
        validated.date,
        validated.targetCalories
      );

      res.json({
        success: true,
        data: plan,
      });
    } catch (err) {
      next(err);
    }
  }

  static async getDailyPlan(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const date = (typeof req.query.date === 'string' && req.query.date)
        ? req.query.date
        : new Date().toISOString().split('T')[0];

      const plan = await PlannerService.getDailyPlan(userId, date);

      res.json({
        success: true,
        data: plan,
      });
    } catch (err) {
      next(err);
    }
  }

  static async saveDailyPlan(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const validated = savePlanSchema.parse(req.body);

      const saved = await PlannerService.saveDailyPlan(userId, validated.date, {
        plannedMeals: validated.plannedMeals,
        workoutRoutineId: validated.workoutRoutineId,
        waterTargetMl: validated.waterTargetMl,
        notes: validated.notes,
        isCompleted: validated.isCompleted,
      });

      res.json({
        success: true,
        data: saved,
      });
    } catch (err) {
      next(err);
    }
  }
}
