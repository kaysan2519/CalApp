import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { app } from '../src/app.js';
import { pool } from '../src/config/db.js';

describe('Phase 4 - Nutrition Core Integration (Real PostgreSQL)', () => {
  let accessToken = '';
  let userId = '';
  let createdItemId = '';
  const today = '2026-10-12';

  beforeAll(async () => {
    // Register a test user
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        email: `nutri_test_${Date.now()}@example.com`,
        password: 'PasswordNutri123!',
        name: 'Siti Rahma',
        age: 24,
        gender: 'female',
        heightCm: 160,
        weightKg: 55,
        activityLevel: 'light',
        goal: 'lose',
      });

    accessToken = res.body.data.accessToken;
    userId = res.body.data.user.id;
  });

  afterAll(async () => {
    if (userId) {
      await pool.query('DELETE FROM users WHERE id = $1', [userId]);
    }
  });

  it('searches foods by query (Indonesian food search)', async () => {
    const res = await request(app)
      .get('/api/v1/nutrition/foods/search?q=nasi')
      .set('Authorization', `Bearer ${accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.length).toBeGreaterThan(0);
    const hasNasiPutih = res.body.data.some((f: any) => f.name_id === 'Nasi Putih');
    expect(hasNasiPutih).toBe(true);
  });

  it('creates custom user food item', async () => {
    const res = await request(app)
      .post('/api/v1/nutrition/foods/custom')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        name: 'Kue Lapis Legit Buatan Rumah',
        servingSize: 50,
        servingUnit: 'potong',
        calories: 190,
        proteinG: 3.5,
        carbsG: 22,
        fatG: 10,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.source).toBe('custom_user');
    expect(res.body.data.name).toBe('Kue Lapis Legit Buatan Rumah');
  });

  it('queries product by barcode (Indomie barcode example)', async () => {
    const res = await request(app)
      .get('/api/v1/nutrition/barcode/089686010924')
      .set('Authorization', `Bearer ${accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.brand).toBe('Indofood');
    expect(res.body.data.calories).toBe('380.00');
  });

  it('returns 404 for non-existent barcode with manual entry suggestion', async () => {
    const res = await request(app)
      .get('/api/v1/nutrition/barcode/999999999999999')
      .set('Authorization', `Bearer ${accessToken}`);

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('PRODUCT_NOT_FOUND');
  });

  it('logs meal item with snapshot data and recalculates meal totals', async () => {
    // Log Lunch: Dada Ayam Panggang, 1.5 porsi
    const res = await request(app)
      .post('/api/v1/nutrition/log')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        logDate: today,
        mealType: 'lunch',
        foodName: 'Dada Ayam Panggang',
        servingQty: 1.5,
        servingUnit: 'porsi',
        calories: 247.5,
        proteinG: 46.5,
        carbsG: 0,
        fatG: 5.4,
        source: 'database',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.id).toBeDefined();
    expect(res.body.data.food_name).toBe('Dada Ayam Panggang');
    expect(res.body.data.snapshot_data).toBeDefined();

    createdItemId = res.body.data.id;
  });

  it('fetches daily summary showing consumed and remaining calories/macros', async () => {
    const res = await request(app)
      .get(`/api/v1/nutrition/daily?date=${today}`)
      .set('Authorization', `Bearer ${accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.consumed.calories).toBe(248);
    expect(res.body.data.consumed.proteinG).toBe(46.5);
    expect(res.body.data.remaining.calories).toBeGreaterThan(0);
    expect(res.body.data.meals.lunch.items.length).toBe(1);
  });

  it('updates meal item quantity and recalculates totals proportionally', async () => {
    // Increase serving from 1.5 to 3.0 (2x)
    const res = await request(app)
      .put(`/api/v1/nutrition/log/${createdItemId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        servingQty: 3.0,
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.calories).toBe('495.00'); // 247.5 * 2
    expect(res.body.data.protein_g).toBe('93.00'); // 46.5 * 2
  });

  it('logs daily water intake and updates total water', async () => {
    const res = await request(app)
      .post('/api/v1/nutrition/water')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        logDate: today,
        amountMl: 500,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.totalWaterMl).toBe(500);

    // Verify reflected in daily summary
    const summaryRes = await request(app)
      .get(`/api/v1/nutrition/daily?date=${today}`)
      .set('Authorization', `Bearer ${accessToken}`);

    expect(summaryRes.body.data.consumed.waterMl).toBe(500);
  });

  it('deletes meal item and immediately updates daily summary', async () => {
    const delRes = await request(app)
      .delete(`/api/v1/nutrition/log/${createdItemId}`)
      .set('Authorization', `Bearer ${accessToken}`);

    expect(delRes.status).toBe(200);
    expect(delRes.body.success).toBe(true);

    const summaryRes = await request(app)
      .get(`/api/v1/nutrition/daily?date=${today}`)
      .set('Authorization', `Bearer ${accessToken}`);

    expect(summaryRes.body.data.consumed.calories).toBe(0);
    expect(summaryRes.body.data.meals.lunch.items.length).toBe(0);
  });

  it('calculates weekly summary averages across 7 days', async () => {
    const res = await request(app)
      .get(`/api/v1/nutrition/summary/weekly?startDate=${today}`)
      .set('Authorization', `Bearer ${accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.averages).toBeDefined();
    expect(res.body.data.averages.dailyCalories).toBeDefined();
  });
});
