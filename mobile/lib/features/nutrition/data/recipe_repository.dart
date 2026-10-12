import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/recipe_models.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RecipeRepository(apiClient: apiClient);
});

class RecipeRepository {
  final ApiClient apiClient;

  RecipeRepository({required this.apiClient});

  Future<List<RecipeItem>> getRecipes({String? query, String? tag, int? maxCalories}) async {
    final response = await apiClient.get(
      '/recipes',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (tag != null && tag.isNotEmpty) 'tag': tag,
        if (maxCalories != null && maxCalories > 0) 'maxCalories': maxCalories,
      },
    );
    final list = response.data['data'] as List;
    return list.map((item) => RecipeItem.fromJson(item)).toList();
  }

  Future<RecipeItem> getRecipeById(String id, {double? servings}) async {
    final response = await apiClient.get(
      '/recipes/$id',
      queryParameters: {
        if (servings != null) 'servings': servings,
      },
    );
    return RecipeItem.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> logRecipeToMeal({
    required String recipeId,
    required String mealType,
    required double servings,
    String? logDate,
  }) async {
    final response = await apiClient.post(
      '/recipes/$recipeId/log-to-meal',
      data: {
        'mealType': mealType,
        'servings': servings,
        if (logDate != null) 'logDate': logDate,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<DailyMenuPlan> generateDailyMenu({String? date, int? targetCalories}) async {
    final response = await apiClient.post(
      '/planner/daily-generator',
      data: {
        if (date != null) 'date': date,
        if (targetCalories != null) 'targetCalories': targetCalories,
      },
    );
    return DailyMenuPlan.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> getDailyPlan({String? date}) async {
    final response = await apiClient.get(
      '/planner/daily',
      queryParameters: {
        if (date != null) 'date': date,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> saveDailyPlan({
    required String date,
    int? waterTargetMl,
    String? notes,
    bool? isCompleted,
    List<dynamic>? plannedMeals,
  }) async {
    final response = await apiClient.post(
      '/planner/daily',
      data: {
        'date': date,
        if (waterTargetMl != null) 'waterTargetMl': waterTargetMl,
        if (notes != null) 'notes': notes,
        if (isCompleted != null) 'isCompleted': isCompleted,
        if (plannedMeals != null) 'plannedMeals': plannedMeals,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}
