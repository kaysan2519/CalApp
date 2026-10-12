class RecipeIngredient {
  final String name;
  final double? qty;
  final String? unit;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  RecipeIngredient({
    required this.name,
    this.qty,
    this.unit,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String? ?? '',
      qty: (json['qty'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      calories: (json['calories'] as num?)?.toDouble(),
      protein: (json['protein'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
    );
  }
}

class RecipeItem {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final int prepTimeMin;
  final int cookTimeMin;
  final int baseServings;
  final double servings;
  final double caloriesPerServing;
  final double proteinPerServing;
  final double carbsPerServing;
  final double fatPerServing;
  final double totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final List<String> dietaryTags;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;

  RecipeItem({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.prepTimeMin = 15,
    this.cookTimeMin = 20,
    this.baseServings = 1,
    this.servings = 1.0,
    required this.caloriesPerServing,
    required this.proteinPerServing,
    required this.carbsPerServing,
    required this.fatPerServing,
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    this.dietaryTags = const [],
    this.ingredients = const [],
    this.instructions = const [],
  });

  factory RecipeItem.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'] as List? ?? [];
    final rawInstructions = json['instructions'] as List? ?? [];
    final rawTags = json['dietary_tags'] as List? ?? [];

    final calPerServing = (json['calories_per_serving'] as num?)?.toDouble() ?? 0.0;
    final protPerServing = (json['protein_per_serving'] as num?)?.toDouble() ?? 0.0;
    final carbPerServing = (json['carbs_per_serving'] as num?)?.toDouble() ?? 0.0;
    final fatPerServing = (json['fat_per_serving'] as num?)?.toDouble() ?? 0.0;

    final curServings = (json['servings'] as num?)?.toDouble() ?? 1.0;
    final totCal = (json['totalCalories'] as num?)?.toDouble() ?? (calPerServing * curServings);
    final totProt = (json['totalProteinG'] as num?)?.toDouble() ?? (protPerServing * curServings);
    final totCarb = (json['totalCarbsG'] as num?)?.toDouble() ?? (carbPerServing * curServings);
    final totFat = (json['totalFatG'] as num?)?.toDouble() ?? (fatPerServing * curServings);

    return RecipeItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      prepTimeMin: (json['prep_time_min'] as num?)?.toInt() ?? 15,
      cookTimeMin: (json['cook_time_min'] as num?)?.toInt() ?? 20,
      baseServings: (json['baseServings'] as num?)?.toInt() ?? 1,
      servings: curServings,
      caloriesPerServing: calPerServing,
      proteinPerServing: protPerServing,
      carbsPerServing: carbPerServing,
      fatPerServing: fatPerServing,
      totalCalories: totCal,
      totalProteinG: totProt,
      totalCarbsG: totCarb,
      totalFatG: totFat,
      dietaryTags: rawTags.map((e) => e.toString()).toList(),
      ingredients: rawIngredients.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>)).toList(),
      instructions: rawInstructions.map((e) => e.toString()).toList(),
    );
  }
}

class PlannedMealItem {
  final String mealType;
  final String mealTitle;
  final String recipeId;
  final String title;
  final double servings;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final List<Map<String, dynamic>> alternatives;

  PlannedMealItem({
    required this.mealType,
    required this.mealTitle,
    required this.recipeId,
    required this.title,
    required this.servings,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.alternatives = const [],
  });

  factory PlannedMealItem.fromJson(Map<String, dynamic> json) {
    return PlannedMealItem(
      mealType: json['mealType'] as String? ?? 'breakfast',
      mealTitle: json['mealTitle'] as String? ?? 'Makan',
      recipeId: json['recipeId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      servings: (json['servings'] as num?)?.toDouble() ?? 1.0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbsG'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fatG'] as num?)?.toDouble() ?? 0.0,
      alternatives: (json['alternatives'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }
}

class DailyMenuPlan {
  final String date;
  final int targetCalories;
  final double totalPlannedCalories;
  final double totalPlannedProtein;
  final double totalPlannedCarbs;
  final double totalPlannedFat;
  final double variancePercent;
  final bool isWithinSafetyBounds;
  final List<PlannedMealItem> meals;
  final String notice;

  DailyMenuPlan({
    required this.date,
    required this.targetCalories,
    required this.totalPlannedCalories,
    required this.totalPlannedProtein,
    required this.totalPlannedCarbs,
    required this.totalPlannedFat,
    required this.variancePercent,
    required this.isWithinSafetyBounds,
    required this.meals,
    required this.notice,
  });

  factory DailyMenuPlan.fromJson(Map<String, dynamic> json) {
    final rawMeals = json['meals'] as List? ?? [];
    return DailyMenuPlan(
      date: json['date'] as String? ?? '',
      targetCalories: (json['targetCalories'] as num?)?.toInt() ?? 2000,
      totalPlannedCalories: (json['totalPlannedCalories'] as num?)?.toDouble() ?? 0.0,
      totalPlannedProtein: (json['totalPlannedProtein'] as num?)?.toDouble() ?? 0.0,
      totalPlannedCarbs: (json['totalPlannedCarbs'] as num?)?.toDouble() ?? 0.0,
      totalPlannedFat: (json['totalPlannedFat'] as num?)?.toDouble() ?? 0.0,
      variancePercent: (json['variancePercent'] as num?)?.toDouble() ?? 0.0,
      isWithinSafetyBounds: json['isWithinSafetyBounds'] as bool? ?? true,
      meals: rawMeals.map((e) => PlannedMealItem.fromJson(e as Map<String, dynamic>)).toList(),
      notice: json['notice'] as String? ?? '',
    );
  }
}
