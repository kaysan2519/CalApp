import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cal/features/today/presentation/master_action_hub_modal.dart';
import 'package:cal/features/workouts/domain/workout_models.dart';
import 'package:cal/features/workouts/presentation/exercise_detail_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Master Action Hub & Exercise Guidance Tests', () {
    testWidgets('MasterActionHubModal renders Food Hub and Workout Hub tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MasterActionHubModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and tabs
      expect(find.text('Pusat Aksi Cepat Cal'), findsOneWidget);
      expect(find.text('Pindai Makanan'), findsOneWidget);
      expect(find.text('Latihan Dunia'), findsOneWidget);

      // Check Food Hub components
      expect(find.text('Pindai Kamera AI'), findsOneWidget);
      expect(find.text('Pindai Barcode'), findsOneWidget);
      expect(find.text('Deskripsi Makanan / Minuman Cepat'), findsOneWidget);
      expect(find.text('Hitung Nilai Gizi AI'), findsOneWidget);

      // Switch to Workout Hub Tab
      await tester.tap(find.text('Latihan Dunia'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Check Workout Hub components
      expect(find.text('AI Workout Generator Sesuai Durasi'), findsOneWidget);
      expect(find.text('Deskripsi Latihan Bebas'), findsOneWidget);
      expect(find.text('Katalog Semua Gerakan di Dunia'), findsOneWidget);
      expect(find.text('15 Menit (Kilat)'), findsOneWidget);
      expect(find.text('30 Menit (Fokus)'), findsOneWidget);
    });

    test('ExerciseDetailModal getExerciseImageUrl provides valid image for all movement categories', () {
      final benchUrl = ExerciseDetailModal.getExerciseImageUrl('Barbell Bench Press', 'Chest', 'barbell');
      final squatUrl = ExerciseDetailModal.getExerciseImageUrl('Barbell Back Squat', 'Quads', 'barbell');
      final pullupUrl = ExerciseDetailModal.getExerciseImageUrl('Pull-Up', 'Back', 'bodyweight');
      final cableUrl = ExerciseDetailModal.getExerciseImageUrl('Cable Chest Fly', 'Chest', 'cable');

      expect(benchUrl.startsWith('https://images.unsplash.com'), isTrue);
      expect(squatUrl.startsWith('https://images.unsplash.com'), isTrue);
      expect(pullupUrl.startsWith('https://images.unsplash.com'), isTrue);
      expect(cableUrl.startsWith('https://images.unsplash.com'), isTrue);
    });

    testWidgets('ExerciseDetailModal displays movement photo, 4-step execution guide, and sets logger', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sampleExercise = ExerciseItem(
        id: 'ex-bench-test',
        name: 'Barbell Bench Press',
        targetMuscle: 'Chest',
        category: 'barbell',
        equipment: 'Barbell & Flat Bench',
        instructions: 'Setup scapula, grip bar, turunkan bar ke tengah dada, dorong kuat ke atas.',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseDetailModal(exercise: sampleExercise),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Barbell Bench Press'), findsWidgets);
      expect(find.text('Chest'), findsWidgets);
      expect(find.text('Arahan Langkah Demi Langkah:'), findsOneWidget);
      expect(find.text('Tips Form Aman & Hindari Cedera:'), findsOneWidget);
      expect(find.text('Catat Set & Repetisi Sesi Ini:'), findsOneWidget);
    });
  });
}
