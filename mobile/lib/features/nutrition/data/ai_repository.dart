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
