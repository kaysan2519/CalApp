class FoodItem {
  final String id;
  final String name;
  final String? nameId;
  final String? brand;
  final String? barcode;
  final double servingSize;
  final String servingUnit;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String source;

  FoodItem({
    required this.id,
    required this.name,
    this.nameId,
    this.brand,
    this.barcode,
    required this.servingSize,
    required this.servingUnit,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.source,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameId: json['name_id'],
      brand: json['brand'],
      barcode: json['barcode'],
      servingSize: (json['serving_size'] as num?)?.toDouble() ?? 100,
      servingUnit: json['serving_unit'] ?? 'gram',
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      source: json['source'] ?? 'database',
    );
  }
}

class MealItem {
  final String id;
  final String? foodItemId;
  final String foodName;
  final double servingQty;
  final String servingUnit;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String source;

  MealItem({
    required this.id,
    this.foodItemId,
    required this.foodName,
    required this.servingQty,
    required this.servingUnit,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.source,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      id: json['id'] ?? '',
      foodItemId: json['foodItemId'] ?? json['food_item_id'],
      foodName: json['foodName'] ?? json['food_name'] ?? '',
      servingQty: (json['servingQty'] ?? json['serving_qty'] as num?)?.toDouble() ?? 1,
      servingUnit: json['servingUnit'] ?? json['serving_unit'] ?? 'porsi',
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      proteinG: (json['proteinG'] ?? json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbsG'] ?? json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fatG'] ?? json['fat_g'] as num?)?.toDouble() ?? 0,
      source: json['source'] ?? 'database',
    );
  }
}

class MealSlot {
  final String? mealLogId;
  final List<MealItem> items;
  final double totalCalories;

  MealSlot({
    this.mealLogId,
    required this.items,
    required this.totalCalories,
  });

  factory MealSlot.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return MealSlot(
      mealLogId: json['mealLogId'],
      items: rawItems.map((item) => MealItem.fromJson(item)).toList(),
      totalCalories: (json['totalCalories'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MacroBreakdown {
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int waterMl;

  MacroBreakdown({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.waterMl,
  });

  factory MacroBreakdown.fromJson(Map<String, dynamic> json) {
    return MacroBreakdown(
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbsG'] as num?)?.toDouble() ?? 0,
      fatG: (json['fatG'] as num?)?.toDouble() ?? 0,
      waterMl: (json['waterMl'] as num?)?.toInt() ?? 0,
    );
  }
}

class DailyNutritionSummary {
  final String logDate;
  final MacroBreakdown target;
  final MacroBreakdown consumed;
  final MacroBreakdown remaining;
  final Map<String, MealSlot> meals;

  DailyNutritionSummary({
    required this.logDate,
    required this.target,
    required this.consumed,
    required this.remaining,
    required this.meals,
  });

  factory DailyNutritionSummary.fromJson(Map<String, dynamic> json) {
    final mealsRaw = json['meals'] as Map<String, dynamic>? ?? {};
    final mealsMap = <String, MealSlot>{};

    for (final entry in mealsRaw.entries) {
      mealsMap[entry.key] = MealSlot.fromJson(entry.value);
    }

    return DailyNutritionSummary(
      logDate: json['logDate'] ?? '',
      target: MacroBreakdown.fromJson(json['target'] ?? {}),
      consumed: MacroBreakdown.fromJson(json['consumed'] ?? {}),
      remaining: MacroBreakdown.fromJson(json['remaining'] ?? {}),
      meals: mealsMap,
    );
  }
}
