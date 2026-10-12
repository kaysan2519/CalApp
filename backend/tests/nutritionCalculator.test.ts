import { describe, it, expect } from 'vitest';
import { NutritionCalculator } from '../src/modules/nutrition/nutritionCalculator.js';

describe('NutritionCalculator - Mifflin-St Jeor Standards', () => {
  it('calculates correct BMR for 70kg, 175cm, 25yo male', () => {
    // 10*70 + 6.25*175 - 5*25 + 5 = 700 + 1093.75 - 125 + 5 = 1673.75 -> 1674
    const bmr = NutritionCalculator.calculateBMR({
      weightKg: 70,
      heightCm: 175,
      age: 25,
      gender: 'male',
    });
    expect(bmr).toBe(1674);
  });

  it('calculates correct BMR for 55kg, 160cm, 28yo female', () => {
    // 10*55 + 6.25*160 - 5*28 - 161 = 550 + 1000 - 140 - 161 = 1249
    const bmr = NutritionCalculator.calculateBMR({
      weightKg: 55,
      heightCm: 160,
      age: 28,
      gender: 'female',
    });
    expect(bmr).toBe(1249);
  });

  it('strictly enforces female calorie floor of 1200 kcal', () => {
    // Very light female trying to lose weight:
    const targets = NutritionCalculator.calculateTargets({
      age: 30,
      gender: 'female',
      weightKg: 45,
      heightCm: 150,
      activityLevel: 'sedentary',
      goal: 'lose',
    });
    // BMR: 10*45 + 6.25*150 - 5*30 - 161 = 450 + 937.5 - 150 - 161 = 1076.5 -> 1077
    // TDEE: 1077 * 1.2 = 1292. Deficit -450 -> 842. Floor is 1200!
    expect(targets.targetCalories).toBe(1200);
  });

  it('strictly enforces male calorie floor of 1500 kcal', () => {
    const targets = NutritionCalculator.calculateTargets({
      age: 35,
      gender: 'male',
      weightKg: 55,
      heightCm: 160,
      activityLevel: 'sedentary',
      goal: 'lose',
    });
    expect(targets.targetCalories).toBeGreaterThanOrEqual(1500);
  });

  it('rejects age under 18 years', () => {
    expect(() => {
      NutritionCalculator.calculateBMR({
        age: 17,
        gender: 'male',
        weightKg: 60,
        heightCm: 170,
      });
    }).toThrow('Usia minimal adalah 18 tahun.');
  });
});
