import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cal/core/network/api_client.dart';
import 'package:cal/core/storage/token_storage.dart';
import 'package:cal/features/workouts/data/workout_repository.dart';
import 'package:cal/features/workouts/domain/workout_models.dart';
import 'package:cal/features/workouts/presentation/workouts_screen.dart';
import 'package:cal/features/workouts/presentation/active_workout_session_sheet.dart';
import 'package:cal/features/workouts/presentation/ai_workout_generator_modal.dart';
import 'package:cal/features/workouts/presentation/body_measurement_modal.dart';

class FakeWorkoutRepository extends WorkoutRepository {
  FakeWorkoutRepository({required super.apiClient});

  final List<ExerciseItem> fakeExercises = [
    ExerciseItem(
      id: 'ex-bench-press',
      name: 'Barbell Bench Press',
      targetMuscle: 'Chest',
      category: 'barbell',
      equipment: 'Barbell',
      instructions: 'Posisikan mata di bawah bar, turunkan bar ke dada tengah dengan kontrol.',
    ),
    ExerciseItem(
      id: 'ex-squat',
      name: 'Barbell Back Squat',
      targetMuscle: 'Quads',
      category: 'barbell',
      equipment: 'Barbell',
      instructions: 'Turun sampai paha sejajar lantai, dorong tumit ke atas.',
    ),
  ];

  final List<WorkoutRoutineItem> fakeRoutines = [
    WorkoutRoutineItem(
      id: 'routine-1',
      title: 'Push Day - Hypertrophy',
      description: 'Latihan dada, bahu, dan triceps intensif',
      daysPerWeek: 3,
      exercises: [
        RoutineExerciseItem(
          id: 're-1',
          exerciseId: 'ex-bench-press',
          name: 'Barbell Bench Press',
          targetMuscle: 'Chest',
          equipment: 'Barbell',
          orderIndex: 0,
          targetSets: 4,
          targetReps: 8,
          restSeconds: 90,
        ),
      ],
    ),
  ];

  final List<WorkoutSessionItem> fakeSessions = [
    WorkoutSessionItem(
      id: 'session-1',
      title: 'Sesi Latihan Pagi',
      startedAt: '2026-10-12T07:00:00Z',
      completedAt: '2026-10-12T07:45:00Z',
      status: 'completed',
      durationSeconds: 2700,
      totalVolumeKg: 2400.0,
      sets: [
        WorkoutSetItem(
          id: 'set-1',
          exerciseId: 'ex-bench-press',
          exerciseName: 'Barbell Bench Press',
          setNumber: 1,
          reps: 8,
          weightKg: 80.0,
          isPR: true,
        ),
      ],
    ),
  ];

  final List<PersonalRecordItem> fakePRs = [
    PersonalRecordItem(
      id: 'pr-1',
      exerciseId: 'ex-bench-press',
      exerciseName: 'Barbell Bench Press',
      targetMuscle: 'Chest',
      maxWeightKg: 85.0,
      maxReps: 5,
      estimated1RM: 95.6,
      achievedAt: '2026-10-12T07:30:00Z',
    ),
  ];

  BodyProgressSummary fakeBodyProgress = BodyProgressSummary(
    latestWeight: 72.5,
    weightDelta: -1.5,
    totalEntries: 2,
    history: [
      BodyMeasurementItem(
        id: 'bm-1',
        measuredDate: '2026-10-12T06:00:00Z',
        weightKg: 72.5,
        waistCm: 81.0,
        notes: 'Pagi hari sebelum sarapan',
      ),
      BodyMeasurementItem(
        id: 'bm-0',
        measuredDate: '2026-10-05T06:00:00Z',
        weightKg: 74.0,
        waistCm: 83.0,
      ),
    ],
  );

  @override
  Future<List<ExerciseItem>> getExercises({String? query, String? muscle, String? equipment}) async {
    return fakeExercises.where((e) {
      if (query != null && !e.name.toLowerCase().contains(query.toLowerCase())) return false;
      if (muscle != null && muscle != 'Semua' && e.targetMuscle.toLowerCase() != muscle.toLowerCase()) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<WorkoutRoutineItem>> getRoutines() async {
    return fakeRoutines;
  }

  @override
  Future<List<WorkoutSessionItem>> getUserSessions() async {
    return fakeSessions;
  }

  @override
  Future<List<PersonalRecordItem>> getPersonalRecords() async {
    return fakePRs;
  }

  @override
  Future<BodyProgressSummary> getBodyMeasurements() async {
    return fakeBodyProgress;
  }

  @override
  Future<WorkoutSessionItem> startSession({required String title, String? routineId}) async {
    return WorkoutSessionItem(
      id: 'session-new-123',
      title: title,
      startedAt: DateTime.now().toIso8601String(),
      status: 'in_progress',
    );
  }

  @override
  Future<Map<String, dynamic>> logSet({
    required String sessionId,
    required String exerciseId,
    required int setNumber,
    required int reps,
    required double weightKg,
    double? rpe,
  }) async {
    return {
      'id': 'set-mock-${DateTime.now().millisecondsSinceEpoch}',
      'sessionId': sessionId,
      'exerciseId': exerciseId,
      'exerciseName': 'Barbell Bench Press',
      'setNumber': setNumber,
      'reps': reps,
      'weightKg': weightKg,
      'isPR': weightKg >= 80,
      'estimated1RM': 90.0,
    };
  }

  @override
  Future<WorkoutSessionItem> finishSession({required String sessionId, String? notes}) async {
    return WorkoutSessionItem(
      id: sessionId,
      title: 'Sesi Selesai',
      startedAt: DateTime.now().toIso8601String(),
      completedAt: DateTime.now().toIso8601String(),
      status: 'completed',
      durationSeconds: 1800,
      totalVolumeKg: 1500.0,
    );
  }

  @override
  Future<Map<String, dynamic>> generateAIWorkout({
    String goal = 'hypertrophy',
    int daysPerWeek = 3,
    String equipment = 'gym',
  }) async {
    return {
      'routineId': 'routine-ai-generated',
      'title': 'AI Hypertrophy Full Body (3 Hari)',
      'description': 'Program latihan optimal disusun oleh AI Coach',
      'exercises': [
        {
          'id': 'ai-ex-1',
          'exerciseId': 'ex-bench-press',
          'name': 'Barbell Bench Press',
          'targetMuscle': 'Chest',
          'targetSets': 3,
          'targetReps': 10,
          'restSeconds': 90,
        },
      ],
    };
  }

  @override
  Future<BodyMeasurementItem> logBodyMeasurement({
    required double weightKg,
    double? waistCm,
    double? chestCm,
    double? hipsCm,
    String? measuredDate,
    String? notes,
  }) async {
    final newItem = BodyMeasurementItem(
      id: 'bm-mock-${DateTime.now().millisecondsSinceEpoch}',
      measuredDate: measuredDate ?? DateTime.now().toIso8601String(),
      weightKg: weightKg,
      waistCm: waistCm,
      chestCm: chestCm,
      hipsCm: hipsCm,
      notes: notes,
    );
    return newItem;
  }
}

void main() {
  late FakeWorkoutRepository fakeRepo;

  setUp(() {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    fakeRepo = FakeWorkoutRepository(apiClient: apiClient);
  });

  Widget createTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: MaterialApp(
        theme: ThemeData(
          primaryColor: const Color(0xFF10B981),
          scaffoldBackgroundColor: const Color(0xFF121212),
        ),
        home: child,
      ),
    );
  }

  group('Fase 7 (Gym & Progres) Widget Tests', () {
    testWidgets('WorkoutsScreen displays 4 tabs and renders routines & history correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(const WorkoutsScreen()));
      await tester.pumpAndSettle();

      // Check App bar title and tabs
      expect(find.text('Gym & Latihan'), findsOneWidget);
      expect(find.text('Sesi & Rutin'), findsOneWidget);
      expect(find.text('Katalog Latihan'), findsOneWidget);
      expect(find.text('Rekor PR'), findsOneWidget);
      expect(find.text('Progres Tubuh'), findsOneWidget);

      // Tab 1 content check
      expect(find.text('Mulai Latihan'), findsOneWidget);
      expect(find.text('AI Rutinitas'), findsOneWidget);
      expect(find.text('Push Day - Hypertrophy'), findsOneWidget);
      expect(find.text('Sesi Latihan Pagi'), findsOneWidget);
      expect(find.textContaining('Total Volume: 2400.0 kg'), findsOneWidget);
    });

    testWidgets('WorkoutsScreen switch to Katalog Latihan, Rekor PR, and Progres Tubuh', (tester) async {
      await tester.pumpWidget(createTestWidget(const WorkoutsScreen()));
      await tester.pumpAndSettle();

      // Switch to Tab 2: Katalog Latihan
      await tester.tap(find.text('Katalog Latihan'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('exercise_search_input')), findsOneWidget);
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('Barbell Back Squat'), findsOneWidget);

      // Switch to Tab 3: Rekor PR
      await tester.tap(find.text('Rekor PR'));
      await tester.pumpAndSettle();

      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('Beban Tertinggi: 85.0 kg × 5 Reps'), findsOneWidget);
      expect(find.text('Estimasi 1RM: 95.6 kg'), findsOneWidget);

      // Switch to Tab 4: Progres Tubuh
      await tester.tap(find.text('Progres Tubuh'));
      await tester.pumpAndSettle();

      expect(find.text('Berat Badan Terkini'), findsOneWidget);
      expect(find.text('72.5 kg'), findsWidgets);
      expect(find.text('-1.5 kg'), findsOneWidget);
      expect(find.byKey(const Key('open_body_measurement_btn')), findsOneWidget);
    });

    testWidgets('ActiveWorkoutSessionSheet logs sets and finishes session', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  ActiveWorkoutSessionSheet.show(ctx, title: 'Uji Sesi Latihan');
                },
                child: const Text('Open Tracker'),
              ),
            ),
          ),
        ),
      );

      // Open Tracker BottomSheet
      await tester.tap(find.text('Open Tracker'));
      await tester.pumpAndSettle();

      expect(find.text('Uji Sesi Latihan'), findsOneWidget);
      expect(find.text('Total Volume'), findsOneWidget);

      // Add set via log set button
      expect(find.byKey(const Key('log_set_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('log_set_btn')));
      await tester.pumpAndSettle();

      // Check logged set in list
      expect(find.textContaining('Set #1'), findsOneWidget);
      expect(find.textContaining('60 kg × 10 reps'), findsOneWidget);

      // Tap Selesai Latihan
      await tester.tap(find.byKey(const Key('finish_workout_btn')));
      await tester.pumpAndSettle();

      // SnackBar verification
      expect(find.textContaining('selesai! Total volume:'), findsOneWidget);
    });

    testWidgets('AiWorkoutGeneratorModal generates workout plan with goal selection', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  AiWorkoutGeneratorModal.show(ctx);
                },
                child: const Text('Open AI Generator'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open AI Generator'));
      await tester.pumpAndSettle();

      expect(find.text('AI Workout Coach'), findsOneWidget);
      expect(find.text('Bina Otot (Hypertrophy)'), findsOneWidget);

      // Tap generate button
      final genBtn = find.byKey(const Key('generate_ai_workout_btn'));
      await tester.ensureVisible(genBtn);
      await tester.tap(genBtn);
      await tester.pumpAndSettle();

      // Check generated plan
      expect(find.text('AI Hypertrophy Full Body (3 Hari)'), findsOneWidget);
      final saveBtn = find.byKey(const Key('save_ai_workout_btn'));
      expect(saveBtn, findsOneWidget);

      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Program latihan berhasil disimpan ke Rutinitas!'), findsOneWidget);
    });

    testWidgets('BodyMeasurementModal validates input and saves measurements', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  BodyMeasurementModal.show(ctx);
                },
                child: const Text('Open Body Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Body Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Catat Ukuran Tubuh'), findsOneWidget);

      // Enter weight and waist
      await tester.enterText(find.byKey(const Key('body_weight_input')), '71.8');
      await tester.enterText(find.byKey(const Key('body_waist_input')), '80.5');
      await tester.enterText(find.byKey(const Key('body_notes_input')), 'Uji coba timbangan');

      await tester.tap(find.byKey(const Key('save_body_measurement_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Ukuran tubuh berhasil dicatat!'), findsOneWidget);
    });
  });
}
