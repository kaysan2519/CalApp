import { Request, Response } from 'express';
import { insightService } from './insightService.js';

export class InsightController {
  async getWeeklyInsights(req: Request, res: Response) {
    try {
      const userId = req.user!.id;
      const insights = await insightService.getWeeklyInsights(userId);
      return res.json({ status: 'success', data: insights });
    } catch (error: any) {
      const statusCode = error?.statusCode ?? 500;
      return res.status(statusCode).json({
        success: false,
        error: {
          code: error?.code ?? 'INTERNAL_SERVER_ERROR',
          message: statusCode === 500 ? 'Terjadi kesalahan pada server.' : error.message,
        },
      });
    }
  }
}

export const insightController = new InsightController();
