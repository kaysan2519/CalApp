import { pool } from '../config/db.js';
import { SEED_FOODS, SEED_RECIPES, SEED_EXERCISES, SEED_ACHIEVEMENTS, SEED_CHALLENGES } from './seedData.js';

export async function runSeed() {
  console.log('[Seed] Seeding database catalogs...');
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. Seed Foods
    for (const food of SEED_FOODS) {
      await client.query(
        `INSERT INTO food_items (name, name_id, brand, barcode, serving_size, serving_unit, calories, protein_g, carbs_g, fat_g, fiber_g, source, license, is_verified)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
         ON CONFLICT (barcode) DO NOTHING`,
        [
          food.name,
          food.name_id,
          food.brand || null,
          food.barcode || null,
          food.serving_size,
          food.serving_unit,
          food.calories,
          food.protein_g,
          food.carbs_g,
          food.fat_g,
          food.fiber_g,
          food.source,
          food.license,
          food.is_verified,
        ]
      );
    }
    console.log(`[Seed] Seeded ${SEED_FOODS.length} food items.`);

    // 2. Seed Recipes
    for (const r of SEED_RECIPES) {
      const existing = await client.query('SELECT id FROM recipes WHERE title = $1', [r.title]);
      if (existing.rows.length === 0) {
        await client.query(
          `INSERT INTO recipes (title, description, prep_time_min, cook_time_min, servings, calories_per_serving, protein_per_serving, carbs_per_serving, fat_per_serving, dietary_tags, ingredients, instructions, is_seed)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, TRUE)`,
          [
            r.title,
            r.description,
            r.prep_time_min,
            r.cook_time_min,
            r.servings,
            r.calories_per_serving,
            r.protein_per_serving,
            r.carbs_per_serving,
            r.fat_per_serving,
            r.dietary_tags,
            JSON.stringify(r.ingredients),
            JSON.stringify(r.instructions),
          ]
        );
      }
    }
    console.log(`[Seed] Seeded ${SEED_RECIPES.length} recipes.`);

    // 3. Seed Exercises (80 items)
    for (const ex of SEED_EXERCISES) {
      const existing = await client.query('SELECT id FROM exercises WHERE name = $1', [ex.name]);
      if (existing.rows.length === 0) {
        await client.query(
          `INSERT INTO exercises (name, target_muscle, category, equipment, is_seed)
           VALUES ($1, $2, $3, $4, TRUE)`,
          [ex.name, ex.target_muscle, ex.category, ex.equipment]
        );
      }
    }
    console.log(`[Seed] Seeded ${SEED_EXERCISES.length} gym exercises.`);

    // 4. Seed Achievements
    for (const ach of SEED_ACHIEVEMENTS) {
      await client.query(
        `INSERT INTO achievements (code, title, description, icon_name, xp_reward)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (code) DO NOTHING`,
        [ach.code, ach.title, ach.description, ach.icon_name, ach.xp_reward]
      );
    }
    console.log(`[Seed] Seeded ${SEED_ACHIEVEMENTS.length} achievements.`);

    // 5. Seed Challenges
    const now = new Date();
    const nextWeek = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    for (const ch of SEED_CHALLENGES) {
      const existing = await client.query('SELECT id FROM challenges WHERE title = $1', [ch.title]);
      if (existing.rows.length === 0) {
        await client.query(
          `INSERT INTO challenges (title, description, challenge_type, target_metric, target_value, xp_reward, starts_at, ends_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
          [ch.title, ch.description, ch.challenge_type, ch.target_metric, ch.target_value, ch.xp_reward, now, nextWeek]
        );
      }
    }
    console.log(`[Seed] Seeded ${SEED_CHALLENGES.length} challenges.`);

    await client.query('COMMIT');
    console.log('[Seed] Database seeding completed successfully.');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[Seed] Seeding failed:', err);
    throw err;
  } finally {
    client.release();
  }
}

if (process.argv[1].endsWith('seed.ts') || process.argv[1].endsWith('seed.js')) {
  runSeed()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}
