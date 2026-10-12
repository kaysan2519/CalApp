class NutritionTargets {
  final int targetCalories;
  final double targetProteinG;
  final double targetCarbsG;
  final double targetFatG;
  final int targetWaterMl;
  final bool isManual;

  NutritionTargets({
    required this.targetCalories,
    required this.targetProteinG,
    required this.targetCarbsG,
    required this.targetFatG,
    required this.targetWaterMl,
    required this.isManual,
  });

  factory NutritionTargets.fromJson(Map<String, dynamic> json) {
    return NutritionTargets(
      targetCalories: (json['target_calories'] as num).toInt(),
      targetProteinG: (json['target_protein_g'] as num).toDouble(),
      targetCarbsG: (json['target_carbs_g'] as num).toDouble(),
      targetFatG: (json['target_fat_g'] as num).toDouble(),
      targetWaterMl: (json['target_water_ml'] as num).toInt(),
      isManual: json['is_manual'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'target_calories': targetCalories,
        'target_protein_g': targetProteinG,
        'target_carbs_g': targetCarbsG,
        'target_fat_g': targetFatG,
        'target_water_ml': targetWaterMl,
        'is_manual': isManual,
      };
}

class User {
  final String id;
  final String email;
  final String name;
  final int age;
  final String gender;
  final double? heightCm;
  final double? weightKg;
  final String activityLevel;
  final String goal;
  final String timezone;
  final NutritionTargets? nutritionTargets;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.age,
    required this.gender,
    this.heightCm,
    this.weightKg,
    required this.activityLevel,
    required this.goal,
    required this.timezone,
    this.nutritionTargets,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      age: (json['age'] as num).toInt(),
      gender: json['gender'] ?? 'neutral',
      heightCm: json['height_cm'] != null ? (json['height_cm'] as num).toDouble() : null,
      weightKg: json['weight_kg'] != null ? (json['weight_kg'] as num).toDouble() : null,
      activityLevel: json['activity_level'] ?? 'moderate',
      goal: json['goal'] ?? 'maintain',
      timezone: json['timezone'] ?? 'Asia/Jakarta',
      nutritionTargets: json['nutritionTargets'] != null
          ? NutritionTargets.fromJson(json['nutritionTargets'])
          : null,
    );
  }
}
