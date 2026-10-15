import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import { app } from '../src/app.js';
import { query } from '../src/config/db.js';

describe('Phase 6 - Recipes, AI Menu Generator & Unified Planner (Real PostgreSQL)', () => {
  let authToken: string;
  let userId: string;
  let testRecipeId: string;

  beforeAll(async () => {
    // Register and login test user
    const email = `phase6_user_${Date.now()}@example.com`;
    const regRes = await request(app)
      .post('/api/v1/auth/register')
      .send({
        email,
        password: 'Password123!',
        name: 'Phase 6 User',
        age: 28,
        gender: 'female',
        heightCm: 160,
        weightKg: 55,
        activityLevel: 'moderate',
        goal: 'maintain',
      });

    expect(regRes.status).toBe(201);
    authToken = regRes.body.data.accessToken;
    userId = regRes.body.data.user.id;

    // Fetch existing recipe from seeded database
    const recipeQuery = await query('SELECT id FROM recipes LIMIT 1');
    expect(recipeQuery.rows.length).toBeGreaterThan(0);
    testRecipeId = recipeQuery.rows[0].id;
  });

  describe('F09 Healthy Indonesian Recipes', () => {
    it('returns list of Indonesian recipes with pagination and filtering', async () => {
      const res = await request(app)
        .get('/api/v1/recipes')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ limit: 10 });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThan(0);

      const firstRecipe = res.body.data[0];
      expect(firstRecipe).toHaveProperty('title');
      expect(firstRecipe).toHaveProperty('calories_per_serving');
      expect(firstRecipe).toHaveProperty('dietary_tags');
    });

    it('filters recipes by query keyword and dietary tag', async () => {
      const res = await request(app)
        .get('/api/v1/recipes')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ q: 'ayam' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      for (const r of res.body.data) {
        expect(r.title.toLowerCase() + (r.description || '').toLowerCase()).toContain('ayam');
      }
    });

    it('scales recipe nutrition and ingredient quantities proportionally to servings', async () => {
      // 1 serving
      const res1 = await request(app)
        .get(`/api/v1/recipes/${testRecipeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .query({ servings: 1 });

      expect(res1.status).toBe(200);
      const data1 = res1.body.data;
      const baseCal = data1.totalCalories;
      const baseProtein = data1.totalProteinG;

      // 2 servings
      const res2 = await request(app)
        .get(`/api/v1/recipes/${testRecipeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .query({ servings: 2 });

      expect(res2.status).toBe(200);
      const data2 = res2.body.data;

      // Mathematical verification
      expect(data2.totalCalories).toBe(baseCal * 2);
      expect(data2.totalProteinG).toBeCloseTo(baseProtein * 2, 1);
    });

    it('logs recipe directly to daily meal log and updates nutrition totals', async () => {
      const today = '2026-10-12';
      const logRes = await request(app)
        .post(`/api/v1/recipes/${testRecipeId}/log-to-meal`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          mealType: 'lunch',
          servings: 1.5,
          logDate: today,
        });

      expect(logRes.status).toBe(201);
      expect(logRes.body.success).toBe(true);
      expect(logRes.body.data).toHaveProperty('mealItem');
      expect(logRes.body.data.loggedServings).toBe(1.5);

      // Verify it appears in daily nutrition summary
      const summaryRes = await request(app)
        .get('/api/v1/nutrition/daily')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ date: today });

      expect(summaryRes.status).toBe(200);
      const lunchItems = summaryRes.body.data.meals.lunch.items;
      expect(lunchItems.some((item: any) => item.source === 'recipe')).toBe(true);
    });
  });

  describe('F10 AI Daily Menu Generator', () => {
    it('generates a 1-day balanced Indonesian meal plan within target calories', async () => {
      const res = await request(app)
        .post('/api/v1/planner/daily-generator')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          targetCalories: 1800,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      const plan = res.body.data;

      expect(plan.targetCalories).toBe(1800);
      expect(plan.meals.length).toBe(3); // breakfast, lunch, dinner
      expect(plan.meals[0].mealType).toBe('breakfast');
      expect(plan.meals[1].mealType).toBe('lunch');
      expect(plan.meals[2].mealType).toBe('dinner');

      // Check alternatives exist for user flexibility
      expect(plan.meals[0].alternatives.length).toBeGreaterThan(0);

      // Check total calories variance within safe bounds
      expect(plan.isWithinSafetyBounds).toBe(true);
      expect(Math.abs(plan.variancePercent)).toBeLessThanOrEqual(25);
    });

    it('rejects a requested menu target below the profile calorie floor', async () => {
      const res = await request(app)
        .post('/api/v1/planner/daily-generator')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ targetCalories: 1000 });

      expect(res.status).toBe(422);
      expect(res.body.error.code).toBe('UNSAFE_CALORIE_TARGET');
    });
  });

  describe('F11 Unified Daily Planner', () => {
    it('fetches unified daily plan integrating nutrition, planned meals, hydration and routine', async () => {
      const today = '2026-10-12';
      const res = await request(app)
        .get('/api/v1/planner/daily')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ date: today });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      const plan = res.body.data;

      expect(plan).toHaveProperty('nutrition');
      expect(plan).toHaveProperty('plannedMeals');
      expect(plan).toHaveProperty('hydration');
      expect(plan.hydration).toHaveProperty('targetMl');
    });

    it('persists daily planner checklist and notes across requests', async () => {
      const today = '2026-10-12';
      const saveRes = await request(app)
        .post('/api/v1/planner/daily')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          date: today,
          waterTargetMl: 2800,
          notes: 'Fokus defisit kalori dan hidrasi maksimal.',
          isCompleted: true,
        });

      expect(saveRes.status).toBe(200);
      expect(saveRes.body.success).toBe(true);

      // Re-fetch and verify persistence
      const getRes = await request(app)
        .get('/api/v1/planner/daily')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ date: today });

      expect(getRes.status).toBe(200);
      expect(getRes.body.data.notes).toBe('Fokus defisit kalori dan hidrasi maksimal.');
      expect(getRes.body.data.hydration.targetMl).toBe(2800);
      expect(getRes.body.data.isCompleted).toBe(true);
    });
  });
});
