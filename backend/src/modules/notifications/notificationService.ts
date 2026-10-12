import { pool } from '../../config/db.js';

export interface NotificationPreferences {
  breakfastReminder: boolean;
  breakfastTime: string; // '07:30'
  lunchReminder: boolean;
  lunchTime: string; // '12:30'
  dinnerReminder: boolean;
  dinnerTime: string; // '19:00'
  waterReminder: boolean;
  waterIntervalHours: number; // 2
  workoutReminder: boolean;
  workoutTime: string; // '17:00'
  gentleTone: boolean; // non-shaming copy
}

const DEFAULT_PREFERENCES: NotificationPreferences = {
  breakfastReminder: true,
  breakfastTime: '07:30',
  lunchReminder: true,
  lunchTime: '12:30',
  dinnerReminder: true,
  dinnerTime: '19:00',
  waterReminder: true,
  waterIntervalHours: 2,
  workoutReminder: true,
  workoutTime: '17:00',
  gentleTone: true,
};

export class NotificationService {
  async getPreferences(userId: string): Promise<NotificationPreferences> {
    const res = await pool.query(
      `SELECT notification_preferences FROM users WHERE id = $1`,
      [userId]
    );

    if (res.rows.length === 0 || !res.rows[0].notification_preferences) {
      return DEFAULT_PREFERENCES;
    }

    return {
      ...DEFAULT_PREFERENCES,
      ...res.rows[0].notification_preferences,
    };
  }

  async updatePreferences(
    userId: string,
    updates: Partial<NotificationPreferences>
  ): Promise<NotificationPreferences> {
    const current = await this.getPreferences(userId);
    const merged = { ...current, ...updates };

    await pool.query(
      `UPDATE users
       SET notification_preferences = $1, updated_at = NOW()
       WHERE id = $2`,
      [JSON.stringify(merged), userId]
    );

    return merged;
  }

  /**
   * Generates localized gentle, non-shaming notification messages
   */
  getScheduledSampleMessages() {
    return [
      {
        type: 'breakfast',
        time: '07:30',
        title: 'Selamat Pagi! ☀️',
        body: 'Waktunya sarapan bergizi untuk mengisi energimu menghadapi hari yang cerah.',
      },
      {
        type: 'water',
        time: 'Setiap 2 Jam',
        title: 'Istirahat & Minum Air 💧',
        body: 'Satu gelas air sejuk akan menyegarkan kembali konsentrasi dan metabolisme tubuhmu.',
      },
      {
        type: 'lunch',
        time: '12:30',
        title: 'Waktunya Makan Siang 🥗',
        body: 'Luangkan waktu sejenak untuk menikmati makan siang lezat dan seimbang.',
      },
      {
        type: 'workout',
        time: '17:00',
        title: 'Waktunya Menggerakkan Tubuh 💪',
        body: 'Gerakan ringan atau sesi gym hari ini akan membuat tidurmu malam ini jauh lebih lelap.',
      },
      {
        type: 'dinner',
        time: '19:00',
        title: 'Makan Malam Santai 🍲',
        body: 'Nikmati makan malam bergizi untuk memulihkan energi setelah seharian beraktivitas.',
      },
    ];
  }
}

export const notificationService = new NotificationService();
