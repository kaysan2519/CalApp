import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/ai_food_models.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AiRepository(apiClient: apiClient);
});

class AiRepository {
  final ApiClient apiClient;

  AiRepository({required this.apiClient});

  Future<AiVisionFoodResponse> analyzeFoodVision(String base64Image) async {
    final response = await apiClient.post(
      '/ai/food-vision',
      data: {'base64Image': base64Image},
    );
    return AiVisionFoodResponse.fromJson(response.data['data']);
  }

  Future<List<AiVisionDraftItem>> refineFoodDraft({
    required List<AiVisionDraftItem> items,
    required String instruction,
  }) async {
    try {
      final response = await apiClient.post(
        '/ai/food-refine',
        data: {
          'items': items.map((i) => i.toJson()).toList(),
          'instruction': instruction,
        },
      );
      final list = (response.data['data']['items'] as List)
          .map((json) => AiVisionDraftItem.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      // Offline fallback: perform deterministic local natural language scaling
      final lower = instruction.toLowerCase().trim();
      return items.map((item) {
        final isTarget = lower.contains(item.foodName.toLowerCase()) ||
            (item.foodName.toLowerCase().contains('nasi') && lower.contains('nasi')) ||
            (item.foodName.toLowerCase().contains('ayam') && lower.contains('ayam')) ||
            items.length == 1;

        if (isTarget && (lower.contains('setengah') || lower.contains('separuh') || lower.contains('1/2'))) {
          return item.copyWith(
            estimatedGrams: (item.estimatedGrams * 0.5).roundToDouble(),
            calories: (item.calories * 0.5).roundToDouble(),
            proteinG: double.parse((item.proteinG * 0.5).toStringAsFixed(1)),
            carbsG: double.parse((item.carbsG * 0.5).toStringAsFixed(1)),
            fatG: double.parse((item.fatG * 0.5).toStringAsFixed(1)),
            portionDescription: '${item.portionDescription} (1/2 porsi)',
          );
        }

        if (item.foodName.toLowerCase().contains('ayam') && (lower.contains('tanpa kulit') || lower.contains('skinless'))) {
          final newFat = (item.fatG * 0.4).clamp(1.0, 999.0);
          final newCal = (item.proteinG * 4 + item.carbsG * 4 + newFat * 9).roundToDouble();
          return item.copyWith(
            foodName: item.foodName.contains('Skinless') ? item.foodName : '${item.foodName} (Skinless)',
            fatG: double.parse(newFat.toStringAsFixed(1)),
            calories: newCal,
          );
        }

        if (lower.contains('tanpa kuah') || lower.contains('tanpa minyak')) {
          final newFat = (item.fatG * 0.5).clamp(1.0, 999.0);
          final newCal = (item.proteinG * 4 + item.carbsG * 4 + newFat * 9).roundToDouble();
          return item.copyWith(
            fatG: double.parse(newFat.toStringAsFixed(1)),
            calories: newCal,
          );
        }

        return item;
      }).toList();
    }
  }

  Future<AiTextFoodResponse> parseFoodText(String text) async {
    final response = await apiClient.post(
      '/ai/food-text',
      data: {'text': text},
    );
    return AiTextFoodResponse.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> sendCoachMessage(String message) async {
    final response = await apiClient.post(
      '/ai/coach/chat',
      data: {'message': message},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateWorkoutPlan({
    String goal = 'hypertrophy',
    int daysPerWeek = 3,
    String equipment = 'gym',
  }) async {
    final response = await apiClient.post(
      '/ai/workout-generator',
      data: {
        'goal': goal,
        'daysPerWeek': daysPerWeek,
        'equipment': equipment,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}
