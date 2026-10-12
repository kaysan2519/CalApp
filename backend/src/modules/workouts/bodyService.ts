import { query } from '../../config/db.js';

export interface BodyMeasurementInput {
  measuredDate?: string;
  weightKg: number;
  waistCm?: number;
  chestCm?: number;
  hipsCm?: number;
  photoUrl?: string;
  photoPoseNotes?: string;
  notes?: string;
}

export class BodyService {
  static async logMeasurement(userId: string, data: BodyMeasurementInput) {
    const date = data.measuredDate || new Date().toISOString().split('T')[0];

    // Simpan ke body_measurements
    const res = await query(
      `INSERT INTO body_measurements (user_id, measured_date, weight_kg, waist_cm, chest_cm, hips_cm, photo_url, photo_pose_notes, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [
        userId,
        date,
        data.weightKg,
        data.waistCm || null,
        data.chestCm || null,
        data.hipsCm || null,
        data.photoUrl || null,
        data.photoPoseNotes || null,
        data.notes || null,
      ]
    );

    // Update bobot terkini di tabel users
    await query('UPDATE users SET weight_kg = $2 WHERE id = $1', [userId, data.weightKg]);

    return res.rows[0];
  }

  static async getMeasurements(userId: string, limit: number = 30) {
    const res = await query(
      `SELECT * FROM body_measurements
       WHERE user_id = $1
       ORDER BY measured_date DESC, created_at DESC
       LIMIT $2`,
      [userId, limit]
    );

    const history = res.rows;
    let weightDelta = 0;
    if (history.length >= 2) {
      const latest = parseFloat(history[0].weight_kg);
      const oldest = parseFloat(history[history.length - 1].weight_kg);
      weightDelta = parseFloat((latest - oldest).toFixed(1));
    }

    return {
      history,
      latestWeight: history[0]?.weight_kg ? parseFloat(history[0].weight_kg) : null,
      weightDelta,
      totalEntries: history.length,
    };
  }
}
