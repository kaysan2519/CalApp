import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cal/core/network/api_client.dart';
import 'package:cal/core/storage/token_storage.dart';
import 'package:cal/features/nutrition/domain/ai_food_models.dart';
import 'package:cal/features/nutrition/domain/nutrition_models.dart';
import 'package:cal/features/nutrition/data/ai_repository.dart';
import 'package:cal/features/nutrition/data/nutrition_repository.dart';
import 'package:cal/features/nutrition/presentation/nutrition_state_notifier.dart';
import 'package:cal/features/nutrition/presentation/text_food_entry_dialog.dart';
import 'package:cal/features/nutrition/presentation/ai_vision_food_sheet.dart';
import 'package:cal/features/nutrition/presentation/ai_coach_screen.dart';

class FakeAiRepository extends AiRepository {
  FakeAiRepository({required super.apiClient});

  @override
  Future<AiTextFoodResponse> parseFoodText(String text) async {
    return AiTextFoodResponse(
      originalText: text,
      notice: 'Dinormalkan ke gram berdasarkan takaran pangan.',
      parsedItems: [
        AiTextParsedItem(
          foodItemId: 'food-rice',
          foodName: 'Nasi Putih',
          quantity: 2.0,
          rawUnit: 'centong',
          normalizedGrams: 200.0,
          standardUnit: 'gram',
          calories: 260.0,
          proteinG: 5.4,
          carbsG: 56.4,
          fatG: 0.6,
        ),
        AiTextParsedItem(
          foodItemId: 'food-chicken',
          foodName: 'Ayam Bakar',
          quantity: 1.0,
          rawUnit: 'potong',
          normalizedGrams: 100.0,
          standardUnit: 'gram',
          calories: 215.0,
          proteinG: 26.0,
          carbsG: 1.0,
          fatG: 11.0,
        ),
      ],
    );
  }

  @override
  Future<AiVisionFoodResponse> analyzeFoodVision(String base64Image) async {
    return AiVisionFoodResponse(
      isFood: true,
      notice: 'Nilai gizi dari foto merupakan estimasi AI.',
      draftItems: [
        AiVisionDraftItem(
          foodItemId: 'food-tempeh',
          foodName: 'Tempe Goreng',
          portionDescription: '2 potong sedang',
          estimatedGrams: 100.0,
          calories: 236.0,
          proteinG: 15.0,
          carbsG: 9.6,
          fatG: 16.4,
          confidenceScore: 0.92,
        ),
      ],
    );
  }

  @override
  Future<List<AiVisionDraftItem>> refineFoodDraft({
    required List<AiVisionDraftItem> items,
    required String instruction,
  }) async {
    return items.map((i) {
      if (instruction.toLowerCase().contains('setengah')) {
        return i.copyWith(
          estimatedGrams: (i.estimatedGrams * 0.5).roundToDouble(),
          calories: (i.calories * 0.5).roundToDouble(),
          proteinG: (i.proteinG * 0.5),
          carbsG: (i.carbsG * 0.5),
          fatG: (i.fatG * 0.5),
        );
      }
      return i;
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> sendCoachMessage(String message) async {
    return {
      'message': 'Berdasarkan data hari ini, asupan protein Anda sudah mencapai target. Bagus sekali!',
      'disclaimer': 'Peringatan: Saran AI Coach hanya untuk panduan gaya hidup sehat.',
    };
  }
}

class FakeNutritionRepository extends NutritionRepository {
  FakeNutritionRepository({required super.apiClient});

  @override
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
    return MealItem(
      id: 'logged-1',
      foodItemId: foodItemId,
      foodName: foodName,
      servingQty: servingQty,
      servingUnit: servingUnit,
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      source: source,
    );
  }
}

class MockNutritionNotifier extends NutritionStateNotifier {
  MockNutritionNotifier(super.repository, super.currentDate) {
    state = AsyncValue.data(
      DailyNutritionSummary(
        logDate: '2026-10-12',
        target: MacroBreakdown(calories: 2000, proteinG: 150, carbsG: 225, fatG: 56, waterMl: 2500),
        consumed: MacroBreakdown(calories: 800, proteinG: 45, carbsG: 90, fatG: 25, waterMl: 1000),
        remaining: MacroBreakdown(calories: 1200, proteinG: 105, carbsG: 135, fatG: 31, waterMl: 1500),
        meals: {
          'breakfast': MealSlot(items: [], totalCalories: 0),
          'lunch': MealSlot(items: [], totalCalories: 0),
          'dinner': MealSlot(items: [], totalCalories: 0),
          'snack': MealSlot(items: [], totalCalories: 0),
        },
      ),
    );
  }

  @override
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
    // Simulated instant success
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenStorage tokenStorage;
  late ApiClient apiClient;

  setUp(() async {
    tokenStorage = TokenStorage();
    apiClient = ApiClient(tokenStorage: tokenStorage);
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        aiRepositoryProvider.overrideWithValue(FakeAiRepository(apiClient: apiClient)),
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

  group('F04 Natural Language Text Food Parser Flow', () {
    testWidgets('parses natural Indonesian meal sentence into gram-normalized items', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableWidget(
          const TextFoodEntryDialog(mealType: 'lunch', mealTitle: 'Makan Siang'),
        ),
      );

      expect(find.text('Input Teks (Makan Siang)'), findsOneWidget);
      expect(find.text('Analisis Teks AI'), findsOneWidget);

      // Enter food text
      await tester.enterText(
        find.byType(TextField),
        'nasi putih 2 centong dan ayam bakar 1 potong',
      );
      await tester.tap(find.text('Analisis Teks AI'));
      await tester.pumpAndSettle();

      // Verify parsed items are rendered
      expect(find.text('Nasi Putih'), findsOneWidget);
      expect(find.text('Ayam Bakar'), findsOneWidget);
      expect(find.textContaining('200g'), findsOneWidget);
      expect(find.text('260 kkal'), findsOneWidget);
      expect(find.text('215 kkal'), findsOneWidget);
      expect(find.text('Simpan 2 Item ke Makan Siang'), findsOneWidget);

      // Tap save
      await tester.tap(find.text('Simpan 2 Item ke Makan Siang'));
      await tester.pumpAndSettle();
    });
  });

  group('F02 AI Vision Food Photo Flow', () {
    testWidgets('scans meal image, displays AI estimate badge, and scales portions', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableWidget(
          const AiVisionFoodSheet(mealType: 'dinner', mealTitle: 'Makan Malam'),
        ),
      );

      expect(find.text('Pindai Makanan AI (Makan Malam)'), findsOneWidget);
      expect(find.text('Ambil Foto / Pindai Sekarang'), findsOneWidget);

      // Trigger scan
      await tester.tap(find.text('Ambil Foto / Pindai Sekarang'));
      await tester.pumpAndSettle();

      // Verify AI estimate notice and detected food
      expect(find.textContaining('Estimasi AI'), findsWidgets);
      expect(find.text('Tempe Goreng'), findsOneWidget);
      expect(find.text('92% yakin'), findsOneWidget);
      expect(find.text('236 kkal'), findsOneWidget);
      expect(find.text('Simpan 1 Makanan ke Makan Malam'), findsOneWidget);
    });

    testWidgets('supports 3D kinetic macro ring, AI co-editor whisper refinement, and verification sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableWidget(
          const AiVisionFoodSheet(mealType: 'lunch', mealTitle: 'Makan Siang'),
        ),
      );

      // Scan meal
      await tester.tap(find.text('Ambil Foto / Pindai Sekarang'));
      await tester.pumpAndSettle();

      // Verify Kinetic 3D Macro Ring and Daily Budget
      expect(find.text('Target Harian: 2.100'), findsOneWidget);
      expect(find.text('27% porsi'), findsOneWidget);
      expect(find.text('KKAL'), findsOneWidget);

      // Verify AI Co-Editor Whisper Chip "Nasi 1/2 Porsi"
      expect(find.text('Nasi 1/2 Porsi'), findsOneWidget);
      await tester.tap(find.text('Nasi 1/2 Porsi'));
      await tester.pumpAndSettle();

      // Verify Slide-to-Log label is visible
      expect(find.text('Geser untuk Verifikasi & Catat ➔'), findsOneWidget);
    });
  });

  group('F08 AI Contextual Coach Flow', () {
    testWidgets('renders coach greeting, medical disclaimer, and handles user questions', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableWidget(const AiCoachScreen()),
      );

      // Verify coach title and disclaimer
      expect(find.text('Cal AI Coach'), findsOneWidget);
      expect(find.textContaining('Bukan saran medis resmi'), findsOneWidget);
      expect(find.textContaining('Halo! Saya Cal AI Coach'), findsOneWidget);

      // Tap quick suggestion chip
      expect(find.text('Rekomendasi protein'), findsOneWidget);
      await tester.tap(find.text('Rekomendasi protein'));
      await tester.pumpAndSettle();

      // Verify user question and AI reply are rendered
      expect(find.text('Beri rekomendasi menu tinggi protein yang mudah didapat'), findsOneWidget);
      expect(find.textContaining('asupan protein Anda sudah mencapai target'), findsOneWidget);
      expect(find.textContaining('Peringatan: Saran AI Coach'), findsWidgets);
    });
  });
}
