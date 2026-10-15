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
  final double? targetWeightKg;
  final String trainingExperience;
  final int trainingDaysPerWeek;
  final List<String> trainingSchedule;
  final List<String> availableEquipment;
  final List<String> foodPreferences;
  final List<String> allergies;
  final List<String> dietaryRestrictions;
  final String? activityLimitations;
  final bool onboardingCompleted;

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
    this.targetWeightKg,
    this.trainingExperience = 'beginner',
    this.trainingDaysPerWeek = 3,
    this.trainingSchedule = const [],
    this.availableEquipment = const [],
    this.foodPreferences = const [],
    this.allergies = const [],
    this.dietaryRestrictions = const [],
    this.activityLimitations,
    this.onboardingCompleted = false,
  });

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }

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
      targetWeightKg: json['target_weight_kg'] != null
          ? (json['target_weight_kg'] as num).toDouble()
          : null,
      trainingExperience: json['training_experience'] ?? 'beginner',
      trainingDaysPerWeek: (json['training_days_per_week'] as num?)?.toInt() ?? 3,
      trainingSchedule: _readStringList(json['training_schedule']),
      availableEquipment: _readStringList(json['available_equipment']),
      foodPreferences: _readStringList(json['food_preferences']),
      allergies: _readStringList(json['allergies']),
      dietaryRestrictions: _readStringList(json['dietary_restrictions']),
      activityLimitations: json['activity_limitations'] as String?,
      onboardingCompleted: json['onboarding_completed'] == true,
    );
  }
}
