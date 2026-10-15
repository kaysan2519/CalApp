import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { app } from '../src/app.js';
import { pool } from '../src/config/db.js';

describe('Phase 3 - Auth, Profile & Persistence Integration (Real PostgreSQL)', () => {
  const testUser = {
    email: `test_user_${Date.now()}@example.com`,
    password: 'SecurePassword123!',
    name: 'Budi Santoso',
    age: 26,
    gender: 'male',
    heightCm: 175,
    weightKg: 72,
    activityLevel: 'moderate',
    goal: 'lose',
  };

  let accessToken = '';
  let refreshToken = '';
  let userId = '';

  afterAll(async () => {
    if (userId) {
      await pool.query('DELETE FROM users WHERE id = $1', [userId]);
    }
  });

  it('rejects registration when age is under 18 (Age Gate)', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        ...testUser,
        email: `minor_${Date.now()}@example.com`,
        age: 17,
      });

    expect(res.status).toBe(422);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('registers user and initializes Mifflin-St Jeor nutrition targets', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send(testUser);

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.email).toBe(testUser.email.toLowerCase());
    expect(res.body.data.accessToken).toBeDefined();
    expect(res.body.data.refreshToken).toBeDefined();

    accessToken = res.body.data.accessToken;
    refreshToken = res.body.data.refreshToken;
    userId = res.body.data.user.id;

    // Verify database record
    const targetQuery = await pool.query('SELECT * FROM user_nutrition_targets WHERE user_id = $1', [userId]);
    expect(targetQuery.rows.length).toBe(1);
    expect(targetQuery.rows[0].target_calories).toBeGreaterThan(1500); // Male floor
    expect(targetQuery.rows[0].is_manual).toBe(false);
  });

  it('authenticates user with correct password on login', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: testUser.email,
        password: testUser.password,
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.accessToken).toBeDefined();
    expect(res.body.data.refreshToken).toBeDefined();
  });

  it('rejects duplicate email regardless of letter casing', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({ ...testUser, email: testUser.email.toUpperCase() });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('EMAIL_ALREADY_EXISTS');
  });

  it('rejects login with wrong password', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: testUser.email,
        password: 'WrongPassword!',
      });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('INVALID_CREDENTIALS');
  });

  it('rotates refresh token and revokes the old one', async () => {
    const res = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.accessToken).toBeDefined();
    expect(res.body.data.refreshToken).toBeDefined();

    const newRefreshToken = res.body.data.refreshToken;
    accessToken = res.body.data.accessToken;

    // Attempting to reuse the old refresh token should be rejected
    const reuseRes = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken });

    expect(reuseRes.status).toBe(401);

    refreshToken = newRefreshToken;
  });

  it('fetches authenticated profile and nutrition targets', async () => {
    const res = await request(app)
      .get('/api/v1/profile')
      .set('Authorization', `Bearer ${accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.name).toBe('Budi Santoso');
    expect(res.body.data.nutritionTargets.target_calories).toBeDefined();
  });

  it('rejects private profile access without a valid token', async () => {
    const res = await request(app).get('/api/v1/profile');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('updates demographics and recalculates nutrition targets automatically', async () => {
    const res = await request(app)
      .put('/api/v1/profile')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        weightKg: 80,
        targetWeightKg: 68,
        trainingExperience: 'intermediate',
        trainingDaysPerWeek: 4,
        trainingSchedule: ['monday', 'thursday'],
        availableEquipment: ['Dumbbell'],
        foodPreferences: ['vegetarian'],
        allergies: ['peanut'],
        dietaryRestrictions: ['halal'],
        activityLimitations: 'Avoid high impact',
        onboardingCompleted: true,
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.weight_kg).toBe('80.00');
    expect(res.body.data.user.target_weight_kg).toBe('68.00');
    expect(res.body.data.user.training_schedule).toEqual(['monday', 'thursday']);
    expect(res.body.data.user.food_preferences).toEqual(['vegetarian']);
    expect(res.body.data.user.onboarding_completed).toBe(true);
    // More weight = higher calories & protein
    expect(res.body.data.nutritionTargets.target_protein_g).toBe('144.00'); // 80 * 1.8
  });

  it('rejects manual nutrition target below safe floor of 1200 kcal', async () => {
    const res = await request(app)
      .put('/api/v1/profile/targets')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        targetCalories: 900, // Dangerous extreme deficit
        targetProteinG: 100,
        targetCarbsG: 80,
        targetFatG: 30,
        targetWaterMl: 2000,
      });

    expect(res.status).toBe(422);
    expect(res.body.success).toBe(false);
  });

  it('enforces the 1500 kcal floor for male profiles', async () => {
    const res = await request(app)
      .put('/api/v1/profile/targets')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        targetCalories: 1200,
        targetProteinG: 100,
        targetCarbsG: 120,
        targetFatG: 40,
        targetWaterMl: 2000,
      });

    expect(res.status).toBe(422);
    expect(res.body.error.message).toContain('1500 kkal');
  });

  it('allows safe manual target override', async () => {
    const res = await request(app)
      .put('/api/v1/profile/targets')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        targetCalories: 2300,
        targetProteinG: 160,
        targetCarbsG: 250,
        targetFatG: 65,
        targetWaterMl: 3000,
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.target_calories).toBe(2300);
    expect(res.body.data.is_manual).toBe(true);
  });

  it('exports complete user data (F22 data export)', async () => {
    const res = await request(app)
      .get('/api/v1/auth/export')
      .set('Authorization', `Bearer ${accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.email).toBe(testUser.email.toLowerCase());
    expect(res.body.data.nutritionTargets).toBeDefined();
    expect(res.body.data.exportedAt).toBeDefined();
  });

  it('hard deletes account and cascades to targets (F22 GDPR/UU PDP account deletion)', async () => {
    const res = await request(app)
      .delete('/api/v1/auth/account')
      .set('Authorization', `Bearer ${accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    // Verify deletion in database
    const userCheck = await pool.query('SELECT * FROM users WHERE id = $1', [userId]);
    expect(userCheck.rows.length).toBe(0);

    const targetCheck = await pool.query('SELECT * FROM user_nutrition_targets WHERE user_id = $1', [userId]);
    expect(targetCheck.rows.length).toBe(0);

    userId = ''; // already cleaned
  });
});
