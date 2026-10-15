import { Request, Response } from 'express';
import { gamificationService } from './gamificationService.js';
import { z } from 'zod';

const awardXpSchema = z.object({
  eventCode: z.enum(['meal_logged', 'workout_completed', 'community_post']),
  activityId: z.string().uuid(),
});

export class GamificationController {
  async getProfile(req: Request, res: Response) {
    try {
      const userId = req.user!.id;
      const profile = await gamificationService.getUserProfile(userId);
      return res.json({ status: 'success', data: profile });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  }

  async getAchievements(req: Request, res: Response) {
    try {
      const userId = req.user!.id;
      const achievements = await gamificationService.getAchievements(userId);
      return res.json({ status: 'success', data: achievements });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  }

  async getLeaderboard(req: Request, res: Response) {
    try {
      const userId = req.user!.id;
      const period = typeof req.query.period === 'string' ? req.query.period : 'weekly';
      if (period !== 'weekly' && period !== 'global') {
        return res.status(422).json({ success: false, error: { code: 'INVALID_PERIOD', message: 'Periode harus weekly atau global.' } });
      }
      const requestedLimit = typeof req.query.limit === 'string' ? Number(req.query.limit) : 50;
      const limit = Number.isInteger(requestedLimit) ? Math.min(100, Math.max(1, requestedLimit)) : 50;
      const leaderboard = await gamificationService.getLeaderboard(userId, limit, period);
      return res.json({ status: 'success', data: leaderboard });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  }

  async getChallenges(req: Request, res: Response) {
    try {
      const userId = req.user!.id;
      const challenges = await gamificationService.getChallenges(userId);
      return res.json({ status: 'success', data: challenges });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  }

  async awardXp(req: Request, res: Response) {
    try {
      const userId = req.user!.id;
      const { eventCode, activityId } = awardXpSchema.parse(req.body);
      const result = await gamificationService.awardActivityXp(userId, eventCode, activityId);

      return res.json({ status: 'success', data: result });
    } catch (error: any) {
      const statusCode = error?.statusCode ?? (error?.name === 'ZodError' ? 422 : 500);
      const code = error?.code ?? (statusCode === 422 ? 'VALIDATION_ERROR' : 'INTERNAL_SERVER_ERROR');
      const message = statusCode === 500 ? 'Terjadi kesalahan pada server.' : error.message;
      return res.status(statusCode).json({ success: false, error: { code, message } });
    }
  }
}

export const gamificationController = new GamificationController();
