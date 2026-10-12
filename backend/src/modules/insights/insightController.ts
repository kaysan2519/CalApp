import { Request, Response } from 'express';
import { insightService } from './insightService.js';

export class InsightController {
  async getWeeklyInsights(req: Request, res: Response) {
    try {
      const userId = req.user!.id;
      const insights = await insightService.getWeeklyInsights(userId);
      return res.json({ status: 'success', data: insights });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  }
}

export const insightController = new InsightController();
