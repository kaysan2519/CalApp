import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/nutrition_repository.dart';
import '../domain/nutrition_models.dart';

final selectedDateProvider = StateProvider<String>((ref) {
  return DateTime.now().toIso8601String().split('T')[0];
});

final nutritionStateProvider = StateNotifierProvider<NutritionStateNotifier, AsyncValue<DailyNutritionSummary>>((ref) {
  final repository = ref.watch(nutritionRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  return NutritionStateNotifier(repository, date);
});

class NutritionStateNotifier extends StateNotifier<AsyncValue<DailyNutritionSummary>> {
  final NutritionRepository _repository;
  String _currentDate;

  NutritionStateNotifier(this._repository, this._currentDate) : super(const AsyncValue.loading()) {
    loadDailySummary(_currentDate);
  }

  Future<void> loadDailySummary(String date) async {
    _currentDate = date;
    state = const AsyncValue.loading();
    try {
      final summary = await _repository.getDailySummary(date);
      state = AsyncValue.data(summary);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logFood({
    required String mealType,
    FoodItem? foodItem,
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
    try {
      await _repository.logMealItem(
        logDate: _currentDate,
        mealType: mealType,
        foodItemId: foodItemId ?? foodItem?.id,
        foodName: foodName,
        servingQty: servingQty,
        servingUnit: servingUnit,
        calories: calories,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        source: source,
      );
      await loadDailySummary(_currentDate);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateItemQuantity(String itemId, double newQty) async {
    try {
      await _repository.updateMealItem(itemId: itemId, servingQty: newQty);
      await loadDailySummary(_currentDate);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _repository.deleteMealItem(itemId);
      await loadDailySummary(_currentDate);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> addWater(int amountMl) async {
    try {
      await _repository.logWater(logDate: _currentDate, amountMl: amountMl);
      await loadDailySummary(_currentDate);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
