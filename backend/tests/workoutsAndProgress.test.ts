import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import { app } from '../src/app.js';
import { query } from '../src/config/db.js';

describe('Phase 7 - Gym Workout Tracker, Routines, AI Generator & Body Progress (Real PostgreSQL)', () => {
  let authToken: string;
  let userId: string;
  let testExerciseId: string;
  let activeSessionId: string;
  let createdRoutineId: string;

  beforeAll(async () => {
    const email = `phase7_user_${Date.now()}@example.com`;
    const regRes = await request(app)
      .post('/api/v1/auth/register')
      .send({
        email,
        password: 'Password123!',
        name: 'Phase 7 Lifter',
        age: 26,
        gender: 'male',
        heightCm: 175,
        weightKg: 75,
        activityLevel: 'heavy',
        goal: 'gain',
      });

    expect(regRes.status).toBe(201);
    authToken = regRes.body.data.accessToken;
    userId = regRes.body.data.user.id;

    // Ambil 1 latihan dari katalog seed exercises (misal Barbell Bench Press)
    const exRes = await query("SELECT id FROM exercises WHERE LOWER(target_muscle) = 'chest' LIMIT 1");
    expect(exRes.rows.length).toBeGreaterThan(0);
    testExerciseId = exRes.rows[0].id;
  });

  describe('F13 Gym Tracker & Live Workout Session with PR Auto-Detection', () => {
    it('fetches exercise catalog with muscle and equipment filters', async () => {
      const res = await request(app)
        .get('/api/v1/workouts/exercises')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ muscle: 'chest' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThan(0);
      for (const ex of res.body.data) {
        expect(ex.target_muscle.toLowerCase()).toBe('chest');
      }
    });

    it('starts a new active live workout session', async () => {
      const res = await request(app)
        .post('/api/v1/workouts/sessions')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Push Day - Hypertrophy Session',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('in_progress');
      expect(res.body.data.user_id).toBe(userId);
      activeSessionId = res.body.data.id;
    });

    it('logs Set 1 with Brzycki 1RM calculation and sets initial Personal Record (PR)', async () => {
      // 60 kg x 10 reps -> 1RM ~80 kg
      const res = await request(app)
        .post(`/api/v1/workouts/sessions/${activeSessionId}/sets`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          exerciseId: testExerciseId,
          setNumber: 1,
          reps: 10,
          weightKg: 60,
          rpe: 8,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.isPersonalRecord).toBe(true);
      expect(res.body.data.estimated1RM).toBeGreaterThan(75);
      expect(res.body.data.set.reps).toBe(10);
      expect(parseFloat(res.body.data.set.weight_kg)).toBe(60);
    });

    it('logs Set 2 with heavier weight and auto-detects improved Personal Record (PR)', async () => {
      // 70 kg x 8 reps -> 1RM ~86.9 kg > 80 kg
      const res = await request(app)
        .post(`/api/v1/workouts/sessions/${activeSessionId}/sets`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          exerciseId: testExerciseId,
          setNumber: 2,
          reps: 8,
          weightKg: 70,
          rpe: 9,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.isPersonalRecord).toBe(true);
      expect(res.body.data.estimated1RM).toBeGreaterThan(83);
    });

    it('logs Set 3 with lighter weight and verifies isPersonalRecord is false', async () => {
      // 50 kg x 12 reps -> 1RM ~72 kg < 86.9 kg -> not PR
      const res = await request(app)
        .post(`/api/v1/workouts/sessions/${activeSessionId}/sets`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          exerciseId: testExerciseId,
          setNumber: 3,
          reps: 12,
          weightKg: 50,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.isPersonalRecord).toBe(false);
    });

    it('finishes workout session and calculates total volume and duration', async () => {
      const res = await request(app)
        .put(`/api/v1/workouts/sessions/${activeSessionId}/finish`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          notes: 'Sesi latihan dada sangat optimal. Otot terpompa maksimal.',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('completed');
      expect(res.body.data.completed_at).toBeDefined();

      // Total Volume: (60*10) + (70*8) + (50*12) = 600 + 560 + 600 = 1760 kg
      expect(parseFloat(res.body.data.total_volume_kg)).toBe(1760);
    });

    it('retrieves user personal records list', async () => {
      const res = await request(app)
        .get('/api/v1/workouts/personal-records')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.length).toBeGreaterThan(0);
      expect(res.body.data[0].exercise_id).toBe(testExerciseId);
      expect(parseFloat(res.body.data[0].max_weight_kg)).toBe(70);
    });
  });

  describe('F14 Workout Routines & Programs', () => {
    it('creates custom workout routine with multiple exercises and rest timers', async () => {
      const res = await request(app)
        .post('/api/v1/workouts/routines')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Upper Body Power Routine',
          description: 'Fokus dada, punggung, dan bahu intensitas tinggi.',
          daysPerWeek: 4,
          exercises: [
            { exerciseId: testExerciseId, targetSets: 4, targetReps: 8, restSeconds: 120 },
          ],
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.title).toBe('Upper Body Power Routine');
      expect(res.body.data.exercises.length).toBe(1);
      expect(res.body.data.exercises[0].restSeconds).toBe(120);
      createdRoutineId = res.body.data.id;
    });

    it('retrieves user routines including templates and custom created routine', async () => {
      const res = await request(app)
        .get('/api/v1/workouts/routines')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      const found = res.body.data.find((r: any) => r.id === createdRoutineId);
      expect(found).toBeDefined();
    });
  });

  describe('F15 AI Workout Generator', () => {
    it('generates structured workout plan via AI and saves as user routine in PostgreSQL', async () => {
      const res = await request(app)
        .post('/api/v1/workouts/ai-generate')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          goal: 'hypertrophy',
          daysPerWeek: 3,
          equipment: 'dumbbell',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('aiPlan');
      expect(res.body.data).toHaveProperty('savedRoutine');
      expect(res.body.data.savedRoutine.days_per_week).toBe(3);
    });
  });

  describe('F12 Body Measurements & Progress Tracking', () => {
    it('logs initial body measurement and updates user current weight', async () => {
      const res = await request(app)
        .post('/api/v1/body/measurements')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          measuredDate: '2026-10-01',
          weightKg: 75.5,
          waistCm: 84.0,
          chestCm: 100.0,
          notes: 'Kondisi sebelum program latihan baru.',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(parseFloat(res.body.data.weight_kg)).toBe(75.5);

      // Verify user weight updated
      const userRes = await query('SELECT weight_kg FROM users WHERE id = $1', [userId]);
      expect(parseFloat(userRes.rows[0].weight_kg)).toBe(75.5);
    });

    it('logs secondary body measurement and calculates weight delta', async () => {
      const res2 = await request(app)
        .post('/api/v1/body/measurements')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          measuredDate: '2026-10-12',
          weightKg: 74.5,
          waistCm: 82.5,
          notes: 'Setelah 11 hari latihan konsisten.',
        });

      expect(res2.status).toBe(201);

      // Get history and delta
      const historyRes = await request(app)
        .get('/api/v1/body/measurements')
        .set('Authorization', `Bearer ${authToken}`);

      expect(historyRes.status).toBe(200);
      expect(historyRes.body.success).toBe(true);
      expect(historyRes.body.data.totalEntries).toBeGreaterThanOrEqual(2);
      expect(historyRes.body.data.latestWeight).toBe(74.5);
      // 74.5 - 75.5 = -1.0 kg
      expect(historyRes.body.data.weightDelta).toBe(-1.0);
    });
  });
});
