// Mifflin-St Jeor Nutrition Calculation Standard (docs/NUTRITION_RULES.md)

export interface UserDemographics {
  age: number;
  gender: 'male' | 'female' | 'neutral' | string;
  weightKg: number;
  heightCm: number;
  activityLevel: 'sedentary' | 'light' | 'moderate' | 'heavy' | 'very_heavy' | string;
  goal: 'lose' | 'maintain' | 'gain' | string;
}

export interface CalculatedNutritionTargets {
  bmr: number;
  tdee: number;
  targetCalories: number;
  targetProteinG: number;
  targetCarbsG: number;
  targetFatG: number;
  targetWaterMl: number;
}

export class NutritionCalculator {
  static readonly MIN_AGE = 18;
  static readonly FEMALE_FLOOR_CALORIES = 1200;
  static readonly MALE_FLOOR_CALORIES = 1500;
  static readonly NEUTRAL_FLOOR_CALORIES = 1350;

  static calculateBMR(demographics: Pick<UserDemographics, 'age' | 'gender' | 'weightKg' | 'heightCm'>): number {
    const { age, gender, weightKg, heightCm } = demographics;

    if (age < this.MIN_AGE) {
      throw new Error('Usia minimal adalah 18 tahun.');
    }

    // Mifflin-St Jeor Formula
    const base = 10 * weightKg + 6.25 * heightCm - 5 * age;

    if (gender === 'male') {
      return Math.round(base + 5);
    } else if (gender === 'female') {
      return Math.round(base - 161);
    } else {
      // Neutral fallback average
      return Math.round(base - 78);
    }
  }

  static getActivityMultiplier(activityLevel: string): number {
    switch (activityLevel) {
      case 'light':
        return 1.375;
      case 'moderate':
        return 1.55;
      case 'heavy':
        return 1.725;
      case 'very_heavy':
        return 1.9;
      case 'sedentary':
      default:
        return 1.2;
    }
  }

  static calculateTargets(demographics: UserDemographics): CalculatedNutritionTargets {
    const bmr = this.calculateBMR(demographics);
    const pal = this.getActivityMultiplier(demographics.activityLevel);
    const tdee = Math.round(bmr * pal);

    // Goal adjustments (conservative)
    let targetCalories = tdee;
    if (demographics.goal === 'lose') {
      targetCalories = tdee - 450; // Conservative ~0.45 kg/week deficit
    } else if (demographics.goal === 'gain') {
      targetCalories = tdee + 350; // Clean lean bulk surplus
    }

    // Enforce safety floor limits
    let floor = this.NEUTRAL_FLOOR_CALORIES;
    if (demographics.gender === 'male') {
      floor = this.MALE_FLOOR_CALORIES;
    } else if (demographics.gender === 'female') {
      floor = this.FEMALE_FLOOR_CALORIES;
    }

    if (targetCalories < floor) {
      targetCalories = floor;
    }

    // Macro distributions:
    // Protein: 1.8g to 2.0g per kg of bodyweight
    const targetProteinG = Math.round(demographics.weightKg * 1.8);
    const proteinCalories = targetProteinG * 4;

    // Fat: ~25% of total calories (minimum 0.7g/kg)
    const fatCalories = Math.round(targetCalories * 0.25);
    const targetFatG = Math.max(Math.round(demographics.weightKg * 0.7), Math.round(fatCalories / 9));

    // Carbs: Remaining calories
    const remainingCalories = Math.max(0, targetCalories - proteinCalories - (targetFatG * 9));
    const targetCarbsG = Math.round(remainingCalories / 4);

    // Daily Water Intake (35ml per kg body weight, min 2000 ml)
    const targetWaterMl = Math.max(2000, Math.round(demographics.weightKg * 35));

    return {
      bmr,
      tdee,
      targetCalories,
      targetProteinG,
      targetCarbsG,
      targetFatG,
      targetWaterMl,
    };
  }
}
