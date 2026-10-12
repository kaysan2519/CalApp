import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cal/features/nutrition/domain/nutrition_models.dart';
import 'package:cal/features/nutrition/presentation/nutrition_screen.dart';
import 'package:cal/features/nutrition/presentation/nutrition_state_notifier.dart';
import 'package:cal/features/nutrition/data/nutrition_repository.dart';
import 'package:cal/core/network/api_client.dart';
import 'package:cal/core/storage/token_storage.dart';

class FakeNutritionRepository extends NutritionRepository {
  final DailyNutritionSummary summary;

  FakeNutritionRepository({required super.apiClient, required this.summary});

  @override
  Future<DailyNutritionSummary> getDailySummary(String date) async {
    return summary;
  }

  @override
  Future<List<FoodItem>> searchFoods({String? query, String? barcode}) async {
    return [
      FoodItem(
        id: 'food-1',
        name: 'White Rice',
        nameId: 'Nasi Putih',
        servingSize: 100,
        servingUnit: 'gram',
        calories: 130,
        proteinG: 2.7,
        carbsG: 28.2,
        fatG: 0.3,
        source: 'database',
      ),
      FoodItem(
        id: 'food-2',
        name: 'Fried Tempeh',
        nameId: 'Tempe Goreng',
        servingSize: 50,
        servingUnit: 'potong',
        calories: 118,
        proteinG: 7.5,
        carbsG: 4.8,
        fatG: 8.2,
        source: 'database',
      ),
    ];
  }
}

class MockNutritionStateNotifier extends NutritionStateNotifier {
  MockNutritionStateNotifier(super.repository, super.currentDate, DailyNutritionSummary initial) {
    state = AsyncValue.data(initial);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final mockSummary = DailyNutritionSummary(
    logDate: '2026-10-12',
    target: MacroBreakdown(calories: 2100, proteinG: 140, carbsG: 220, fatG: 65, waterMl: 2500),
    consumed: MacroBreakdown(calories: 520, proteinG: 38, carbsG: 55, fatG: 14, waterMl: 750),
    remaining: MacroBreakdown(calories: 1580, proteinG: 102, carbsG: 165, fatG: 51, waterMl: 1750),
    meals: {
      'breakfast': MealSlot(
        totalCalories: 520,
        items: [
          MealItem(
            id: 'item-1',
            foodName: 'Nasi Putih & Telur Dadar',
            servingQty: 1.0,
            servingUnit: 'porsi',
            calories: 520,
            proteinG: 38,
            carbsG: 55,
            fatG: 14,
            source: 'database',
          ),
        ],
      ),
      'lunch': MealSlot(totalCalories: 0, items: []),
      'dinner': MealSlot(totalCalories: 0, items: []),
      'snack': MealSlot(totalCalories: 0, items: []),
    },
  );

  Widget createTestWidget(DailyNutritionSummary summary) {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final repo = FakeNutritionRepository(apiClient: apiClient, summary: summary);

    return ProviderScope(
      overrides: [
        nutritionRepositoryProvider.overrideWithValue(repo),
        nutritionStateProvider.overrideWith(
          (ref) => MockNutritionStateNotifier(repo, '2026-10-12', summary),
        ),
      ],
      child: const MaterialApp(
        home: NutritionScreen(),
      ),
    );
  }

  group('Phase 4 - Nutrition UI & Flow Tests', () {
    testWidgets('NutritionScreen displays overview, 4 meal slots, and water tracker', (tester) async {
      await tester.pumpWidget(createTestWidget(mockSummary));
      await tester.pumpAndSettle();

      expect(find.text('Nutrisi & Makanan'), findsOneWidget);
      expect(find.text('520 / 2100 kkal'), findsOneWidget);
      expect(find.text('Sisa 1580 kkal'), findsOneWidget);

      // Verify all 4 slots
      expect(find.text('Sarapan'), findsOneWidget);
      expect(find.text('Makan Siang'), findsOneWidget);
      expect(find.text('Makan Malam'), findsOneWidget);
      expect(find.text('Camilan'), findsOneWidget);

      // Verify logged meal item in breakfast
      expect(find.text('Nasi Putih & Telur Dadar'), findsOneWidget);

      // Verify water tracker
      expect(find.text('Konsumsi Air'), findsOneWidget);
      expect(find.text('750 / 2500 ml'), findsOneWidget);
      expect(find.text('+250 ml'), findsOneWidget);
      expect(find.text('+500 ml'), findsOneWidget);
    });

    testWidgets('Add food button opens search modal bottom sheet with food candidates', (tester) async {
      await tester.pumpWidget(createTestWidget(mockSummary));
      await tester.pumpAndSettle();

      final addButtons = find.widgetWithText(OutlinedButton, 'Tambah Makanan');
      expect(addButtons, findsNWidgets(4));

      // Tap on first slot (Sarapan)
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      // Modal title and search field should appear
      expect(find.text('Catat ke Sarapan'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Candidates from FakeNutritionRepository should be listed
      expect(find.text('Nasi Putih'), findsOneWidget);
      expect(find.text('Tempe Goreng'), findsOneWidget);
    });
  });
}
