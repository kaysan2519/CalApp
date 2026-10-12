import { query } from '../../config/db.js';
import { AIService } from '../ai/aiService.js';

export interface ExerciseFilter {
  muscle?: string;
  category?: string;
  equipment?: string;
  query?: string;
}

export class WorkoutService {
  /**
   * Rumus Brzycki untuk estimasi 1-Rep Max (1RM)
   * 1RM = weight / (1.0278 - (0.0278 * reps))
   */
  static calculate1RM(weightKg: number, reps: number): number {
    if (reps <= 0 || weightKg <= 0) return 0;
    if (reps === 1) return weightKg;
    const est = weightKg / (1.0278 - 0.0278 * reps);
    return parseFloat(est.toFixed(1));
  }

  // --- Katalog Latihan (Exercises Catalog) ---
  static async getExercises(filter: ExerciseFilter = {}) {
    const conditions: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (filter.query && filter.query.trim()) {
      conditions.push(`LOWER(name) LIKE $${idx}`);
      values.push(`%${filter.query.toLowerCase()}%`);
      idx++;
    }

    if (filter.muscle && filter.muscle !== 'all') {
      conditions.push(`LOWER(target_muscle) = $${idx}`);
      values.push(filter.muscle.toLowerCase());
      idx++;
    }

    if (filter.equipment && filter.equipment !== 'all') {
      conditions.push(`LOWER(equipment) = $${idx}`);
      values.push(filter.equipment.toLowerCase());
      idx++;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const sql = `SELECT * FROM exercises ${whereClause} ORDER BY name ASC`;
    const res = await query(sql, values);
    return res.rows;
  }

  static async getExerciseById(id: string) {
    const res = await query('SELECT * FROM exercises WHERE id = $1', [id]);
    if (res.rows.length === 0) {
      throw { statusCode: 404, code: 'EXERCISE_NOT_FOUND', message: 'Latihan tidak ditemukan.' };
    }
    return res.rows[0];
  }

  // --- Rutinitas Latihan (Routines) ---
  static async getRoutines(userId: string) {
    const res = await query(
      `SELECT r.*,
        COALESCE(
          json_agg(
            json_build_object(
              'id', re.id,
              'exerciseId', e.id,
              'name', e.name,
              'targetMuscle', e.target_muscle,
              'equipment', e.equipment,
              'orderIndex', re.order_index,
              'targetSets', re.target_sets,
              'targetReps', re.target_reps,
              'restSeconds', re.rest_seconds
            ) ORDER BY re.order_index ASC
          ) FILTER (WHERE re.id IS NOT NULL), '[]'
        ) as exercises
       FROM workout_routines r
       LEFT JOIN workout_routine_exercises re ON r.id = re.routine_id
       LEFT JOIN exercises e ON re.exercise_id = e.id
       WHERE r.user_id = $1 OR r.is_template = TRUE
       GROUP BY r.id
       ORDER BY r.is_template ASC, r.created_at DESC`,
      [userId]
    );
    return res.rows;
  }

  static async createRoutine(userId: string, data: {
    title: string;
    description?: string;
    daysPerWeek?: number;
    exercises: Array<{ exerciseId: string; targetSets?: number; targetReps?: number; restSeconds?: number }>;
  }) {
    const routineRes = await query(
      `INSERT INTO workout_routines (user_id, title, description, days_per_week, is_template)
       VALUES ($1, $2, $3, $4, FALSE)
       RETURNING *`,
      [userId, data.title, data.description || null, data.daysPerWeek || 3]
    );
    const routine = routineRes.rows[0];

    for (let i = 0; i < data.exercises.length; i++) {
      const ex = data.exercises[i];
      await query(
        `INSERT INTO workout_routine_exercises (routine_id, exercise_id, order_index, target_sets, target_reps, rest_seconds)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [routine.id, ex.exerciseId, i, ex.targetSets || 3, ex.targetReps || 10, ex.restSeconds || 90]
      );
    }

    return await this.getRoutineById(userId, routine.id);
  }

  static async getRoutineById(userId: string, routineId: string) {
    const res = await query(
      `SELECT r.*,
        COALESCE(
          json_agg(
            json_build_object(
              'id', re.id,
              'exerciseId', e.id,
              'name', e.name,
              'targetMuscle', e.target_muscle,
              'equipment', e.equipment,
              'orderIndex', re.order_index,
              'targetSets', re.target_sets,
              'targetReps', re.target_reps,
              'restSeconds', re.rest_seconds
            ) ORDER BY re.order_index ASC
          ) FILTER (WHERE re.id IS NOT NULL), '[]'
        ) as exercises
       FROM workout_routines r
       LEFT JOIN workout_routine_exercises re ON r.id = re.routine_id
       LEFT JOIN exercises e ON re.exercise_id = e.id
       WHERE r.id = $1 AND (r.user_id = $2 OR r.is_template = TRUE)
       GROUP BY r.id`,
      [routineId, userId]
    );

    if (res.rows.length === 0) {
      throw { statusCode: 404, code: 'ROUTINE_NOT_FOUND', message: 'Rutinitas latihan tidak ditemukan.' };
    }
    return res.rows[0];
  }

  // --- Sesi Latihan Aktif (Live Workout Sessions) ---
  static async startSession(userId: string, data: { title: string; routineId?: string }) {
    const res = await query(
      `INSERT INTO workout_sessions (user_id, routine_id, title, started_at, status)
       VALUES ($1, $2, $3, NOW(), 'in_progress')
       RETURNING *`,
      [userId, data.routineId || null, data.title]
    );
    return res.rows[0];
  }

  static async logSet(userId: string, sessionId: string, data: {
    exerciseId: string;
    setNumber: number;
    reps: number;
    weightKg: number;
    rpe?: number;
  }) {
    // Verifikasi kepemilikan sesi
    const sessionRes = await query('SELECT * FROM workout_sessions WHERE id = $1 AND user_id = $2', [sessionId, userId]);
    if (sessionRes.rows.length === 0) {
      throw { statusCode: 404, code: 'SESSION_NOT_FOUND', message: 'Sesi latihan tidak ditemukan.' };
    }

    const estimated1RM = this.calculate1RM(data.weightKg, data.reps);

    // Cek Rekor Pribadi (PR)
    let isPR = false;
    const prRes = await query(
      'SELECT * FROM personal_records WHERE user_id = $1 AND exercise_id = $2',
      [userId, data.exerciseId]
    );

    if (prRes.rows.length === 0) {
      if (data.weightKg > 0) {
        isPR = true;
        await query(
          `INSERT INTO personal_records (user_id, exercise_id, max_weight_kg, max_reps, estimated_1rm, achieved_at)
           VALUES ($1, $2, $3, $4, $5, NOW())`,
          [userId, data.exerciseId, data.weightKg, data.reps, estimated1RM]
        );
      }
    } else {
      const currentPR = prRes.rows[0];
      const prev1RM = parseFloat(currentPR.estimated_1rm);
      const prevWeight = parseFloat(currentPR.max_weight_kg);

      if (data.weightKg > prevWeight || estimated1RM > prev1RM) {
        isPR = true;
        await query(
          `UPDATE personal_records
           SET max_weight_kg = GREATEST(max_weight_kg, $3),
               max_reps = CASE WHEN $3 >= max_weight_kg THEN $4 ELSE max_reps END,
               estimated_1rm = GREATEST(estimated_1rm, $5),
               achieved_at = NOW()
           WHERE user_id = $1 AND exercise_id = $2`,
          [userId, data.exerciseId, data.weightKg, data.reps, estimated1RM]
        );
      }
    }

    // Catat set
    const setRes = await query(
      `INSERT INTO workout_sets (session_id, exercise_id, set_number, reps, weight_kg, rpe, is_personal_record)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [sessionId, data.exerciseId, data.setNumber, data.reps, data.weightKg, data.rpe || null, isPR]
    );

    // Update total volume akumulatif sesi
    const volumeDelta = data.reps * data.weightKg;
    await query(
      `UPDATE workout_sessions
       SET total_volume_kg = total_volume_kg + $2
       WHERE id = $1`,
      [sessionId, volumeDelta]
    );

    return {
      set: setRes.rows[0],
      isPersonalRecord: isPR,
      estimated1RM,
    };
  }

  static async finishSession(userId: string, sessionId: string, notes?: string) {
    const sessionRes = await query(
      'SELECT started_at FROM workout_sessions WHERE id = $1 AND user_id = $2',
      [sessionId, userId]
    );
    if (sessionRes.rows.length === 0) {
      throw { statusCode: 404, code: 'SESSION_NOT_FOUND', message: 'Sesi latihan tidak ditemukan.' };
    }

    const startedAt = new Date(sessionRes.rows[0].started_at).getTime();
    const durationSeconds = Math.max(60, Math.round((Date.now() - startedAt) / 1000));

    // Hitung total volume akurat dari seluruh set
    const volRes = await query(
      `SELECT COALESCE(SUM(reps * weight_kg), 0) as total_volume
       FROM workout_sets WHERE session_id = $1`,
      [sessionId]
    );
    const totalVolumeKg = parseFloat(volRes.rows[0].total_volume);

    const updateRes = await query(
      `UPDATE workout_sessions
       SET status = 'completed',
           completed_at = NOW(),
           duration_seconds = $3,
           total_volume_kg = $4,
           notes = COALESCE($5, notes)
       WHERE id = $1 AND user_id = $2
       RETURNING *`,
      [sessionId, userId, durationSeconds, totalVolumeKg, notes || null]
    );

    return updateRes.rows[0];
  }

  static async getUserSessions(userId: string, limit: number = 20) {
    const res = await query(
      `SELECT s.*,
        COUNT(ws.id) as total_sets,
        COALESCE(
          json_agg(
            json_build_object(
              'id', ws.id,
              'exerciseId', ws.exercise_id,
              'exerciseName', e.name,
              'setNumber', ws.set_number,
              'reps', ws.reps,
              'weightKg', ws.weight_kg,
              'isPR', ws.is_personal_record
            ) ORDER BY ws.set_number ASC
          ) FILTER (WHERE ws.id IS NOT NULL), '[]'
        ) as sets
       FROM workout_sessions s
       LEFT JOIN workout_sets ws ON s.id = ws.session_id
       LEFT JOIN exercises e ON ws.exercise_id = e.id
       WHERE s.user_id = $1
       GROUP BY s.id
       ORDER BY s.started_at DESC
       LIMIT $2`,
      [userId, limit]
    );
    return res.rows;
  }

  static async getUserPersonalRecords(userId: string) {
    const res = await query(
      `SELECT pr.*, e.name as exercise_name, e.target_muscle, e.equipment
       FROM personal_records pr
       JOIN exercises e ON pr.exercise_id = e.id
       WHERE pr.user_id = $1
       ORDER BY pr.achieved_at DESC`,
      [userId]
    );
    return res.rows;
  }

  // --- F15: AI Workout Generator & Auto-save to Routine ---
  static async generateAndSaveAIWorkout(userId: string, goal: string, daysPerWeek: number, equipment: string) {
    const generated = await AIService.generateWorkout(goal, daysPerWeek, equipment);

    // Ambil latihan dari database yang cocok dengan equipment
    const dbExercises = await query(
      'SELECT id, name, target_muscle FROM exercises WHERE LOWER(equipment) LIKE $1 LIMIT 5',
      [`%${equipment.toLowerCase()}%`]
    );

    const exerciseList = dbExercises.rows.map((ex, idx) => ({
      exerciseId: ex.id,
      targetSets: 3,
      targetReps: goal === 'strength' ? 6 : 10,
      restSeconds: goal === 'strength' ? 120 : 90,
    }));

    if (exerciseList.length === 0) {
      // Fallback ke 3 latihan sembarang di DB
      const anyEx = await query('SELECT id FROM exercises LIMIT 3');
      for (const e of anyEx.rows) {
        exerciseList.push({ exerciseId: e.id, targetSets: 3, targetReps: 10, restSeconds: 90 });
      }
    }

    // Buat rutinitas di database
    const title = `AI Program: ${goal.toUpperCase()} (${daysPerWeek} Hari)`;
    const routine = await this.createRoutine(userId, {
      title,
      description: generated.weeklyOverview || `Program latihan khusus ${goal} dengan alat ${equipment}.`,
      daysPerWeek,
      exercises: exerciseList,
    });

    return {
      aiPlan: generated,
      savedRoutine: routine,
    };
  }
}
