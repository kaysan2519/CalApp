import { Request, Response } from 'express';
import { notificationService } from './notificationService.js';

export class NotificationController {
  async getPreferences(req: Request, res: Response) {
    try {
      const userId = req.user!.id;
      const prefs = await notificationService.getPreferences(userId);
      const samples = notificationService.getScheduledSampleMessages();
      return res.json({ status: 'success', data: { preferences: prefs, scheduledReminders: samples } });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  }

  async updatePreferences(req: Request, res: Response) {
    try {
      const userId = req.user!.id;
      const updates = req.body;
      const updated = await notificationService.updatePreferences(userId, updates);
      return res.json({ status: 'success', data: updated });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  }
}

export const notificationController = new NotificationController();
