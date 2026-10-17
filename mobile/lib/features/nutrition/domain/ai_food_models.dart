class AiVisionDraftItem {
  final String? foodItemId;
  final String foodName;
  final String portionDescription;
  final double estimatedGrams;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double confidenceScore;
  final bool isAiEstimate;

  AiVisionDraftItem({
    this.foodItemId,
    required this.foodName,
    required this.portionDescription,
    required this.estimatedGrams,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.confidenceScore,
    this.isAiEstimate = true,
  });

  factory AiVisionDraftItem.fromJson(Map<String, dynamic> json) {
    return AiVisionDraftItem(
      foodItemId: json['foodItemId'] as String?,
      foodName: json['foodName'] as String? ?? 'Makanan',
      portionDescription: json['portionDescription'] as String? ?? '',
      estimatedGrams: (json['estimatedGrams'] as num?)?.toDouble() ?? 100.0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbsG'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fatG'] as num?)?.toDouble() ?? 0.0,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.8,
      isAiEstimate: json['isAiEstimate'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (foodItemId != null) 'foodItemId': foodItemId,
      'foodName': foodName,
      'portionDescription': portionDescription,
      'estimatedGrams': estimatedGrams,
      'calories': calories,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatG': fatG,
      'confidenceScore': confidenceScore,
      'isAiEstimate': isAiEstimate,
    };
  }

  AiVisionDraftItem copyWith({
    String? foodItemId,
    String? foodName,
    String? portionDescription,
    double? estimatedGrams,
    double? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? confidenceScore,
    bool? isAiEstimate,
  }) {
    return AiVisionDraftItem(
      foodItemId: foodItemId ?? this.foodItemId,
      foodName: foodName ?? this.foodName,
      portionDescription: portionDescription ?? this.portionDescription,
      estimatedGrams: estimatedGrams ?? this.estimatedGrams,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      isAiEstimate: isAiEstimate ?? this.isAiEstimate,
    );
  }
}

class AiVisionFoodResponse {
  final bool isFood;
  final String? nonFoodReason;
  final List<AiVisionDraftItem> draftItems;
  final String notice;

  AiVisionFoodResponse({
    required this.isFood,
    this.nonFoodReason,
    required this.draftItems,
    required this.notice,
  });

  factory AiVisionFoodResponse.fromJson(Map<String, dynamic> json) {
    return AiVisionFoodResponse(
      isFood: json['isFood'] as bool? ?? false,
      nonFoodReason: json['nonFoodReason'] as String?,
      draftItems: (json['draftItems'] as List? ?? [])
          .map((item) => AiVisionDraftItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      notice: json['notice'] as String? ?? 'Estimasi AI. Sesuaikan porsi sebelum menyimpan.',
    );
  }
}

class AiTextParsedItem {
  final String? foodItemId;
  final String foodName;
  final double quantity;
  final String rawUnit;
  final double normalizedGrams;
  final String standardUnit;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String source;

  AiTextParsedItem({
    this.foodItemId,
    required this.foodName,
    required this.quantity,
    required this.rawUnit,
    required this.normalizedGrams,
    required this.standardUnit,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.source = 'ai_text_parsed',
  });

  factory AiTextParsedItem.fromJson(Map<String, dynamic> json) {
    return AiTextParsedItem(
      foodItemId: json['foodItemId'] as String?,
      foodName: json['foodName'] as String? ?? 'Item Makanan',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      rawUnit: json['rawUnit'] as String? ?? 'porsi',
      normalizedGrams: (json['normalizedGrams'] as num?)?.toDouble() ?? 100.0,
      standardUnit: json['standardUnit'] as String? ?? 'gram',
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbsG'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fatG'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] as String? ?? 'ai_text_parsed',
    );
  }
}

class AiTextFoodResponse {
  final String originalText;
  final List<AiTextParsedItem> parsedItems;
  final String notice;

  AiTextFoodResponse({
    required this.originalText,
    required this.parsedItems,
    required this.notice,
  });

  factory AiTextFoodResponse.fromJson(Map<String, dynamic> json) {
    return AiTextFoodResponse(
      originalText: json['originalText'] as String? ?? '',
      parsedItems: (json['parsedItems'] as List? ?? [])
          .map((item) => AiTextParsedItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      notice: json['notice'] as String? ?? 'Dinormalkan ke gram berdasarkan takaran pangan.',
    );
  }
}

class CoachChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final String? disclaimer;
  final DateTime timestamp;

  CoachChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.disclaimer,
    required this.timestamp,
  });
}
