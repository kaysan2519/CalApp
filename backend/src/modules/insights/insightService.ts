import { pool } from '../../config/db.js';

export interface WeeklyInsightSummary {
  hasData: boolean;
  daysLogged: number;
  averageCalories: number;
  targetCalories: number;
  calorieDeltaPercent: number;
  proteinAdherencePercent: number;
  totalWorkoutVolumeKg: number;
  averageWaterMl: number;
  narrative: string;
}

export class InsightService {
  async getWeeklyInsights(userId: string): Promise<WeeklyInsightSummary> {
    const client = await pool.connect();

    try {
      // 1. Fetch user targets
      const targetRes = await client.query(
        `SELECT target_calories, target_protein_g, target_water_ml
         FROM user_nutrition_targets WHERE user_id = $1`,
        [userId]
      );
      const targets = targetRes.rows[0];
      if (!targets) {
        throw { statusCode: 409, code: 'NUTRITION_TARGETS_NOT_SET', message: 'Target nutrisi belum tersedia untuk profil ini.' };
      }
      const targetCalories = Number(targets.target_calories);
      const targetProtein = Number(targets.target_protein_g);

      // 2. Fetch last 7 days nutrition logs from meal_logs & meal_log_items
      const nutritionRes = await client.query(
        `SELECT ml.log_date,
                COALESCE(SUM(mi.calories), 0) as total_calories,
                COALESCE(SUM(mi.protein_g), 0) as total_protein_g
         FROM meal_logs ml
         JOIN meal_log_items mi ON ml.id = mi.meal_log_id
         WHERE ml.user_id = $1
           AND ml.log_date >= (CURRENT_DATE - INTERVAL '6 days')
         GROUP BY ml.log_date
         ORDER BY ml.log_date ASC`,
        [userId]
      );

      const nutritionLogs = nutritionRes.rows;
      const daysLogged = nutritionLogs.length;

      // 3. Fetch last 7 days water logs
      const waterRes = await client.query(
        `SELECT COALESCE(SUM(amount_ml), 0) as total_water
         FROM water_logs
         WHERE user_id = $1
           AND log_date >= (CURRENT_DATE - INTERVAL '6 days')`,
        [userId]
      );
      const totalWaterPeriod = parseInt(waterRes.rows[0]?.total_water || '0', 10);

      // 4. Fetch last 7 days workout sessions
      const workoutRes = await client.query(
        `SELECT COALESCE(SUM(total_volume_kg), 0) as total_volume
         FROM workout_sessions
         WHERE user_id = $1
           AND status = 'completed'
           AND started_at >= (NOW() - INTERVAL '7 days')`,
        [userId]
      );
      const totalWorkoutVolume = parseFloat(workoutRes.rows[0]?.total_volume || '0');

      if (daysLogged === 0 && totalWorkoutVolume === 0 && totalWaterPeriod === 0) {
        return {
          hasData: false,
          daysLogged: 0,
          averageCalories: 0,
          targetCalories,
          calorieDeltaPercent: 0,
          proteinAdherencePercent: 0,
          totalWorkoutVolumeKg: 0,
          averageWaterMl: 0,
          narrative: 'Belum ada catatan nutrisi atau latihan dalam 7 hari terakhir. Mulai catat makanan dan sesi gym Anda hari ini untuk melihat analisis perkembangan!',
        };
      }

      // Calculations
      let sumCalories = 0;
      let proteinMetDays = 0;

      for (const log of nutritionLogs) {
        const cal = parseFloat(log.total_calories || '0');
        const prot = parseFloat(log.total_protein_g || '0');

        sumCalories += cal;
        if (prot >= targetProtein * 0.85) {
          proteinMetDays += 1;
        }
      }

      const avgCalories = daysLogged > 0 ? Math.round(sumCalories / daysLogged) : 0;
      const avgWater = daysLogged > 0 ? Math.round(totalWaterPeriod / daysLogged) : totalWaterPeriod;
      const proteinAdherence = daysLogged > 0 ? Math.round((proteinMetDays / daysLogged) * 100) : 0;
      const calorieDelta = targetCalories > 0 ? Math.round(((avgCalories - targetCalories) / targetCalories) * 100) : 0;

      // Deterministic Habit Narrative Generation
      let narrative = '';
      if (daysLogged >= 5) {
        narrative += 'Konsistensi pencatatan Anda minggu ini sangat luar biasa! ';
      } else if (daysLogged > 0) {
        narrative += `Anda telah mencatat selama ${daysLogged} hari minggu ini. `;
      }

      if (daysLogged > 0) {
        if (Math.abs(calorieDelta) <= 10) {
          narrative += `Asupan kalori harian rata-rata (${avgCalories} kkal) sangat presisi mendekati target (${targetCalories} kkal). `;
        } else if (calorieDelta < -10) {
          narrative += `Rata-rata kalori Anda (${avgCalories} kkal) berada di bawah target. Pastikan tetap menjaga energi yang cukup untuk pemulihan tubuh. `;
        } else {
          narrative += `Rata-rata kalori Anda (${avgCalories} kkal) berada di atas target. Perhatikan camilan atau porsi di luar jam makan utama. `;
        }

        if (proteinAdherence >= 80) {
          narrative += `Target protein tercapai ${proteinAdherence}% dari hari pencatatan—sangat baik untuk pertumbuhan dan pemulihan otot! `;
        } else {
          narrative += `Kepatuhan protein tercapai ${proteinAdherence}%. Pertimbangkan menambah sumber protein lokal seperti tempe, tahu, atau dada ayam. `;
        }
      }

      if (totalWorkoutVolume > 0) {
        narrative += `Total beban latihan gym Anda mencapai ${totalWorkoutVolume.toLocaleString('id-ID')} kg volume!`;
      }

      return {
        hasData: true,
        daysLogged,
        averageCalories: avgCalories,
        targetCalories,
        calorieDeltaPercent: calorieDelta,
        proteinAdherencePercent: proteinAdherence,
        totalWorkoutVolumeKg: totalWorkoutVolume,
        averageWaterMl: avgWater,
        narrative: narrative.trim(),
      };
    } finally {
      client.release();
    }
  }
}

export const insightService = new InsightService();
