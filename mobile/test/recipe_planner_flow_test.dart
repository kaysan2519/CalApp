import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cal/core/network/api_client.dart';
import 'package:cal/features/nutrition/data/recipe_repository.dart';
import 'package:cal/features/nutrition/data/nutrition_repository.dart';
import 'package:cal/features/nutrition/domain/recipe_models.dart';
import 'package:cal/features/nutrition/domain/nutrition_models.dart';
import 'package:cal/features/nutrition/presentation/nutrition_state_notifier.dart';
import 'package:cal/features/nutrition/presentation/recipes_screen.dart';
import 'package:cal/features/nutrition/presentation/daily_menu_modal.dart';
import 'package:cal/features/today/presentation/today_screen.dart';
import 'package:cal/features/auth/data/auth_repository.dart';
import 'package:cal/features/auth/domain/auth_models.dart';
import 'package:cal/features/auth/presentation/auth_state_notifier.dart';
import 'test_support.dart';

class FakeRecipeRepository extends RecipeRepository {
  FakeRecipeRepository({required super.apiClient});

  @override
  Future<List<RecipeItem>> getRecipes({String? query, String? tag, int? maxCalories}) async {
    final all = [
      RecipeItem(
        id: 'recipe-1',
        title: 'Ayam Panggang Kuning Sehat',
        description: 'Dada ayam tanpa kulit dipanggang kunyit.',
        caloriesPerServing: 195,
        proteinPerServing: 34,
        carbsPerServing: 4,
        fatPerServing: 3.5,
        totalCalories: 195,
        totalProteinG: 34,
        totalCarbsG: 4,
        totalFatG: 3.5,
        dietaryTags: ['Tinggi Protein', 'Rendah Lemak'],
        ingredients: [
          RecipeIngredient(name: 'Dada Ayam', qty: 250, unit: 'gram'),
        ],
        instructions: ['Marinasi dada ayam lalu panggang hingga matang.'],
      ),
      RecipeItem(
        id: 'recipe-2',
        title: 'Pepes Tahu Kemangi',
        description: 'Tahu kukus rempah wangi.',
        caloriesPerServing: 125,
        proteinPerServing: 10,
        carbsPerServing: 7,
        fatPerServing: 5,
        totalCalories: 125,
        totalProteinG: 10,
        totalCarbsG: 7,
        totalFatG: 5,
        dietaryTags: ['Vegetarian'],
        ingredients: [
          RecipeIngredient(name: 'Tahu Putih', qty: 150, unit: 'gram'),
        ],
        instructions: ['Campur tahu dan bumbu halus lalu kukus.'],
      ),
    ];

    if (tag != null) {
      return all.where((r) => r.dietaryTags.contains(tag)).toList();
    }
    if (query != null && query.isNotEmpty) {
      return all.where((r) => r.title.toLowerCase().contains(query.toLowerCase())).toList();
    }
    return all;
  }

  @override
  Future<Map<String, dynamic>> logRecipeToMeal({
    required String recipeId,
    required String mealType,
    required double servings,
    String? logDate,
  }) async {
    return {
      'success': true,
      'loggedServings': servings,
    };
  }

  @override
  Future<DailyMenuPlan> generateDailyMenu({String? date, int? targetCalories}) async {
    return DailyMenuPlan(
      date: '2026-10-12',
      targetCalories: 2000,
      totalPlannedCalories: 1950,
      totalPlannedProtein: 140,
      totalPlannedCarbs: 220,
      totalPlannedFat: 55,
      variancePercent: -2.5,
      isWithinSafetyBounds: true,
      notice: 'Menu harian seimbang dirancang dalam toleransi -2.5% dari target Anda.',
      meals: [
        PlannedMealItem(
          mealType: 'breakfast',
          mealTitle: 'Sarapan',
          recipeId: 'r-1',
          title: 'Oatmeal Pisang Kayu Manis',
          servings: 1.0,
          calories: 450,
          proteinG: 22,
          carbsG: 70,
          fatG: 8,
          alternatives: [{'title': 'Telur Rebus & Roti Gandum'}],
        ),
        PlannedMealItem(
          mealType: 'lunch',
          mealTitle: 'Makan Siang',
          recipeId: 'r-2',
          title: 'Ayam Panggang Kuning Sehat',
          servings: 2.0,
          calories: 800,
          proteinG: 68,
          carbsG: 80,
          fatG: 20,
          alternatives: [{'title': 'Soto Ayam Bening'}],
        ),
        PlannedMealItem(
          mealType: 'dinner',
          mealTitle: 'Makan Malam',
          recipeId: 'r-3',
          title: 'Pepes Tahu Kemangi',
          servings: 1.5,
          calories: 700,
          proteinG: 50,
          carbsG: 70,
          fatG: 27,
          alternatives: [{'title': 'Tumis Tempe Buncis'}],
        ),
      ],
    );
  }
}

class FakeNutritionRepository extends NutritionRepository {
  FakeNutritionRepository({required super.apiClient});

  @override
  Future<DailyNutritionSummary> getDailySummary(String date) async {
    return DailyNutritionSummary(
      logDate: date,
      target: MacroBreakdown(calories: 2000, proteinG: 140, carbsG: 220, fatG: 65, waterMl: 2500),
      consumed: MacroBreakdown(calories: 950, proteinG: 65, carbsG: 110, fatG: 30, waterMl: 1250),
      remaining: MacroBreakdown(calories: 1050, proteinG: 75, carbsG: 110, fatG: 35, waterMl: 1250),
      meals: {
        'breakfast': MealSlot(items: [], totalCalories: 0),
        'lunch': MealSlot(items: [], totalCalories: 0),
        'dinner': MealSlot(items: [], totalCalories: 0),
        'snack': MealSlot(items: [], totalCalories: 0),
      },
    );
  }
}

class MockNutritionNotifier extends NutritionStateNotifier {
  MockNutritionNotifier(super.repository, super.currentDate) {
    state = AsyncValue.data(
      DailyNutritionSummary(
        logDate: '2026-10-12',
        target: MacroBreakdown(calories: 2000, proteinG: 140, carbsG: 220, fatG: 65, waterMl: 2500),
        consumed: MacroBreakdown(calories: 950, proteinG: 65, carbsG: 110, fatG: 30, waterMl: 1250),
        remaining: MacroBreakdown(calories: 1050, proteinG: 75, carbsG: 110, fatG: 35, waterMl: 1250),
        meals: {
          'breakfast': MealSlot(items: [], totalCalories: 0),
          'lunch': MealSlot(items: [], totalCalories: 0),
          'dinner': MealSlot(items: [], totalCalories: 0),
          'snack': MealSlot(items: [], totalCalories: 0),
        },
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient apiClient;
  late InMemoryTokenStorage tokenStorage;

  setUp(() {
    tokenStorage = InMemoryTokenStorage();
    apiClient = ApiClient(tokenStorage: tokenStorage);
  });

  Widget buildTestableWidget(Widget child) {
    final todayKey = const [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ][DateTime.now().weekday - 1];
    final user = User(
      id: 'test-user',
      email: 'test@example.com',
      name: 'Pengguna Tes',
      age: 28,
      gender: 'female',
      heightCm: 165,
      weightKg: 65,
      activityLevel: 'moderate',
      goal: 'fitness',
      timezone: 'Asia/Jakarta',
      trainingSchedule: [todayKey],
      onboardingCompleted: true,
    );
    final authRepository = StaticAuthRepository(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
      user: user,
    );

    return ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
        apiClientProvider.overrideWithValue(apiClient),
        authRepositoryProvider.overrideWithValue(authRepository),
        authStateProvider.overrideWith((ref) => StaticAuthStateNotifier(authRepository, user)),
        recipeRepositoryProvider.overrideWithValue(FakeRecipeRepository(apiClient: apiClient)),
        nutritionRepositoryProvider.overrideWithValue(FakeNutritionRepository(apiClient: apiClient)),
        nutritionStateProvider.overrideWith(
          (ref) => MockNutritionNotifier(ref.watch(nutritionRepositoryProvider), '2026-10-12'),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('F09 Healthy Indonesian Recipes Flow', () {
    testWidgets('lists recipes, filters by tag, adjusts portions and logs meal', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget(const RecipesScreen()));
      await tester.pumpAndSettle();

      // Verify list items rendered
      expect(find.text('Resep Sehat Nusantara'), findsOneWidget);
      expect(find.text('Ayam Panggang Kuning Sehat'), findsOneWidget);
      expect(find.text('Pepes Tahu Kemangi'), findsOneWidget);

      // Tap on first recipe to open detail sheet
      await tester.tap(find.text('Ayam Panggang Kuning Sehat'));
      await tester.pumpAndSettle();

      // Verify detail sheet opened with base 1x serving macros
      expect(find.text('195 kkal'), findsWidgets);
      expect(find.text('Bahan-Bahan:'), findsOneWidget);

      // Adjust portion to 2x
      expect(find.text('2.0x'), findsOneWidget);
      await tester.tap(find.text('2.0x'));
      await tester.pumpAndSettle();

      // Verify scaled calories: 195 * 2 = 390 kcal
      expect(find.text('390 kkal'), findsOneWidget);

      // Tap 'Catat ke Buku Makan'
      expect(find.text('Catat ke Buku Makan'), findsOneWidget);
      await tester.tap(find.text('Catat ke Buku Makan'));
      await tester.pumpAndSettle();

      // Verify success snackbar
      expect(find.textContaining('berhasil dicatat!'), findsOneWidget);
    });
  });

  group('F10 AI Daily Menu Generator Flow', () {
    testWidgets('generates 1-day balanced menu within calorie tolerance', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget(const DailyMenuModal()));
      await tester.pumpAndSettle();

      // Verify title & meals rendered
      expect(find.text('Menu Harian AI'), findsOneWidget);
      expect(find.text('Total: 1950 / 2000 kkal'), findsOneWidget);
      expect(find.text('Toleransi -2.5%'), findsOneWidget);

      expect(find.text('Oatmeal Pisang Kayu Manis'), findsOneWidget);
      expect(find.text('Ayam Panggang Kuning Sehat'), findsOneWidget);
      expect(find.text('Pepes Tahu Kemangi'), findsOneWidget);

      // Verify apply button exists and taps
      expect(find.text('Terapkan ke Catatan'), findsOneWidget);
      await tester.tap(find.text('Terapkan ke Catatan'));
      await tester.pumpAndSettle();

      expect(find.textContaining('berhasil diterapkan'), findsOneWidget);
    });
  });

  group('F11 Unified Daily Planner Flow (TodayScreen)', () {
    testWidgets('renders server nutrition totals, hydration target, and profile-based workout schedule', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableWidget(const TodayScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Cal'), findsOneWidget);
      expect(find.text('950 / 2000 kkal'), findsOneWidget);
      expect(find.text('Sisa 1050 kkal'), findsOneWidget);

      // Quick action buttons
      expect(find.text('Menu AI Hari Ini'), findsOneWidget);
      expect(find.text('Resep Sehat'), findsOneWidget);

      // Hydration & Routine
      expect(find.text('Target Hidrasi'), findsOneWidget);
      expect(find.text('1250 / 2500 ml terpenuhi'), findsOneWidget);
      expect(find.text('Jadwal Latihan Hari Ini'), findsOneWidget);
      expect(find.text('Hari ini termasuk jadwal latihan pilihanmu.'), findsOneWidget);
      expect(find.textContaining('Push Day'), findsNothing);
    });
  });
}
