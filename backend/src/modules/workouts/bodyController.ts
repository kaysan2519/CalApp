import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { BodyService } from './bodyService.js';

const measurementSchema = z.object({
  measuredDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  weightKg: z.number().min(30).max(300, 'Berat badan harus realistis (30–300 kg)'),
  waistCm: z.number().min(30).max(250).optional(),
  chestCm: z.number().min(30).max(250).optional(),
  hipsCm: z.number().min(30).max(250).optional(),
  photoUrl: z.string().url().optional(),
  photoPoseNotes: z.string().optional(),
  notes: z.string().optional(),
});

export class BodyController {
  static async logMeasurement(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = measurementSchema.parse(req.body);
      const result = await BodyService.logMeasurement(req.user!.id, validated);
      res.status(201).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  static async getMeasurements(req: Request, res: Response, next: NextFunction) {
    try {
      const limit = req.query.limit ? Number(req.query.limit) : 30;
      const result = await BodyService.getMeasurements(req.user!.id, limit);
      res.json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }
}
