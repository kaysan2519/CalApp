import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cal/core/network/api_client.dart';
import 'package:cal/core/storage/token_storage.dart';
import 'package:cal/features/today/data/insight_repository.dart';
import 'package:cal/features/today/domain/insight_models.dart';
import 'package:cal/features/today/presentation/weekly_insight_card.dart';

class FakeInsightRepository extends InsightRepository {
  final WeeklyInsightSummary summary;

  FakeInsightRepository({required super.apiClient, required this.summary});

  @override
  Future<WeeklyInsightSummary> getWeeklyInsights() async {
    return summary;
  }
}

void main() {
  Widget createTestWidget(InsightRepository repo) {
    return ProviderScope(
      overrides: [
        insightRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16.0),
            child: WeeklyInsightCard(),
          ),
        ),
      ),
    );
  }

  group('F19 Weekly Insight Card Widget Tests', () {
    testWidgets('renders 7-day metrics, protein adherence, and habit narrative when data exists', (tester) async {
      final tokenStorage = TokenStorage();
      final apiClient = ApiClient(tokenStorage: tokenStorage);
      final fakeRepo = FakeInsightRepository(
        apiClient: apiClient,
        summary: WeeklyInsightSummary(
          hasData: true,
          daysLogged: 6,
          averageCalories: 2050,
          targetCalories: 2100,
          calorieDeltaPercent: -2,
          proteinAdherencePercent: 85,
          totalWorkoutVolumeKg: 4200.0,
          averageWaterMl: 2200,
          narrative: 'Konsistensi pencatatan Anda minggu ini sangat luar biasa! Asupan kalori sangat presisi.',
        ),
      );

      await tester.pumpWidget(createTestWidget(fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Analisis & Tren 7 Hari'), findsOneWidget);
      expect(find.text('6 Hari Tercatat'), findsOneWidget);
      expect(find.text('2050 kkal'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('4200 kg'), findsOneWidget);
      expect(find.textContaining('Konsistensi pencatatan Anda minggu ini'), findsOneWidget);
    });

    testWidgets('renders friendly invitation when no data has been logged yet', (tester) async {
      final tokenStorage = TokenStorage();
      final apiClient = ApiClient(tokenStorage: tokenStorage);
      final fakeRepo = FakeInsightRepository(
        apiClient: apiClient,
        summary: WeeklyInsightSummary(
          hasData: false,
          daysLogged: 0,
          averageCalories: 0,
          targetCalories: 2000,
          calorieDeltaPercent: 0,
          proteinAdherencePercent: 0,
          totalWorkoutVolumeKg: 0,
          averageWaterMl: 0,
          narrative: 'Mulai catat makanan dan latihan hari ini untuk melihat analisis perkembangan mingguan Anda.',
        ),
      );

      await tester.pumpWidget(createTestWidget(fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Insight Progres Mingguan'), findsOneWidget);
      expect(find.textContaining('Mulai catat makanan dan latihan hari ini'), findsOneWidget);
    });
  });
}
