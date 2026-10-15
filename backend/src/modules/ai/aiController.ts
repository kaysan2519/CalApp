import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { AIService } from './aiService.js';

const visionSchema = z.object({
  base64Image: z.string().min(10, 'Data gambar tidak valid atau kosong'),
});

const textSchema = z.object({
  text: z.string().min(3, 'Teks deskripsi makanan minimal 3 karakter'),
});

const coachSchema = z.object({
  message: z.string().min(2, 'Pesan chat minimal 2 karakter'),
});

const workoutGenSchema = z.object({
  goal: z.string().default('hypertrophy'),
  daysPerWeek: z.number().int().min(1).max(7).default(3),
  equipment: z.string().default('gym'),
});

export class AIController {
  static async foodVision(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = visionSchema.parse(req.body);
      const result = await AIService.analyzeFoodVision(validated.base64Image);
      res.json({
        success: true,
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  static async foodText(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = textSchema.parse(req.body);
      const result = await AIService.parseFoodText(validated.text);
      res.json({
        success: true,
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  static async coachChat(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const validated = coachSchema.parse(req.body);
      const result = await AIService.coachChat(userId, validated.message);
      res.json({
        success: true,
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  static async workoutGenerator(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = workoutGenSchema.parse(req.body);
      const result = await AIService.generateWorkout(validated.goal, validated.daysPerWeek, validated.equipment);
      res.json({
        success: true,
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  static async profileRecommendations(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await AIService.generateProfileRecommendations(req.user!.id);
      res.json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }
}
