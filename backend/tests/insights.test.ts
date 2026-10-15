import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { app } from '../src/app.js';
import { pool } from '../src/config/db.js';

describe('Phase 9 - F19 Weekly Insights Integration', () => {
  let authToken: string;
  let userId: string;

  beforeAll(async () => {
    const email = `insights_${Date.now()}@example.com`;
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        email,
        password: 'Password123!',
        name: 'Andi Insightful',
        age: 26,
        heightCm: 170,
        weightKg: 65,
      });

    expect(res.status).toBe(201);
    authToken = res.body.data.accessToken;
    userId = res.body.data.user.id;
  });

  afterAll(async () => {
    if (userId) await pool.query('DELETE FROM users WHERE id = $1', [userId]);
  });

  it('handles empty state gracefully without crashing and distinguishes no-data from zero', async () => {
    const res = await request(app)
      .get('/api/v1/insights/weekly')
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data.hasData).toBe(false);
    expect(res.body.data.daysLogged).toBe(0);
    expect(res.body.data.averageCalories).toBe(0);
    expect(res.body.data.narrative).toContain('Belum ada catatan');
  });

  it('calculates deterministic 7-day average, protein adherence, and gym volume with narrative', async () => {
    // 1. Log a meal
    const today = new Date().toISOString().slice(0, 10);
    const mealRes = await request(app)
      .post('/api/v1/nutrition/log')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        logDate: today,
        mealType: 'lunch',
        foodName: 'Dada Ayam Panggang & Nasi Merah',
        servingQty: 1,
        servingUnit: 'porsi',
        calories: 550,
        proteinG: 45,
        carbsG: 60,
        fatG: 10,
      });
    expect(mealRes.status).toBe(201);

    // 2. Log workout session
    const exRes = await pool.query('SELECT id FROM exercises LIMIT 1');
    const exerciseId = exRes.rows[0].id;

    const sessionRes = await request(app)
      .post('/api/v1/workouts/sessions')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ title: 'Sesi Latihan Punggung' });

    const sessionId = sessionRes.body.data.id;

    await request(app)
      .post(`/api/v1/workouts/sessions/${sessionId}/sets`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        exerciseId,
        setNumber: 1,
        reps: 10,
        weightKg: 50,
      });

    await request(app)
      .put(`/api/v1/workouts/sessions/${sessionId}/finish`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({});

    // 3. Request weekly insights
    const res = await request(app)
      .get('/api/v1/insights/weekly')
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data.hasData).toBe(true);
    expect(res.body.data.daysLogged).toBeGreaterThanOrEqual(1);
    expect(res.body.data.averageCalories).toBeGreaterThan(0);
    expect(res.body.data.totalWorkoutVolumeKg).toBeGreaterThanOrEqual(500);
    expect(res.body.data.narrative.length).toBeGreaterThan(20);
  });

  it('reports missing nutrition targets instead of substituting generic values', async () => {
    await pool.query('DELETE FROM user_nutrition_targets WHERE user_id = $1', [userId]);
    const res = await request(app)
      .get('/api/v1/insights/weekly')
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('NUTRITION_TARGETS_NOT_SET');
  });
});
