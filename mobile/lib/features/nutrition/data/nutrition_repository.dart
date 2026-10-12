import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/nutrition_models.dart';

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NutritionRepository(apiClient: apiClient);
});

class NutritionRepository {
  final ApiClient apiClient;

  NutritionRepository({required this.apiClient});

  Future<DailyNutritionSummary> getDailySummary(String date) async {
    final response = await apiClient.get('/nutrition/daily', queryParameters: {'date': date});
    return DailyNutritionSummary.fromJson(response.data['data']);
  }

  Future<List<FoodItem>> searchFoods({String? query, String? barcode}) async {
    final response = await apiClient.get(
      '/nutrition/foods/search',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
      },
    );
    final list = response.data['data'] as List;
    return list.map((item) => FoodItem.fromJson(item)).toList();
  }

  Future<MealItem> logMealItem({
    required String logDate,
    required String mealType,
    String? foodItemId,
    required String foodName,
    required double servingQty,
    required String servingUnit,
    required double calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    String source = 'database',
  }) async {
    final response = await apiClient.post('/nutrition/log', data: {
      'logDate': logDate,
      'mealType': mealType,
      'foodItemId': foodItemId,
      'foodName': foodName,
      'servingQty': servingQty,
      'servingUnit': servingUnit,
      'calories': calories,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatG': fatG,
      'source': source,
    });
    return MealItem.fromJson(response.data['data']);
  }

  Future<MealItem> updateMealItem({required String itemId, required double servingQty}) async {
    final response = await apiClient.put('/nutrition/log/$itemId', data: {
      'servingQty': servingQty,
    });
    return MealItem.fromJson(response.data['data']);
  }

  Future<void> deleteMealItem(String itemId) async {
    await apiClient.delete('/nutrition/log/$itemId');
  }

  Future<int> logWater({required String logDate, required int amountMl}) async {
    final response = await apiClient.post('/nutrition/water', data: {
      'logDate': logDate,
      'amountMl': amountMl,
    });
    return (response.data['data']['totalWaterMl'] as num).toInt();
  }
}
