import { Request, Response } from 'express';
import { gamificationService } from './gamificationService.js';

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
      const limit = parseInt(req.query.limit as string, 10) || 50;
      const leaderboard = await gamificationService.getLeaderboard(userId, limit);
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
      const { eventCode, xpAmount, idempotencyKey, metadata } = req.body;

      if (!eventCode || typeof xpAmount !== 'number' || !idempotencyKey) {
        return res.status(400).json({
          status: 'error',
          message: 'eventCode, xpAmount (number), and idempotencyKey are required',
        });
      }

      const result = await gamificationService.awardXp(
        userId,
        eventCode,
        xpAmount,
        idempotencyKey,
        metadata || {}
      );

      return res.json({ status: 'success', data: result });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  }
}

export const gamificationController = new GamificationController();
