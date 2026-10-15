import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/workout_models.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WorkoutRepository(apiClient: apiClient);
});

class WorkoutRepository {
  final ApiClient apiClient;

  WorkoutRepository({required this.apiClient});

  // --- Katalog Latihan ---
  Future<List<ExerciseItem>> getExercises({String? query, String? muscle, String? equipment}) async {
    final response = await apiClient.get(
      '/workouts/exercises',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (muscle != null && muscle.isNotEmpty) 'muscle': muscle,
        if (equipment != null && equipment.isNotEmpty) 'equipment': equipment,
      },
    );
    final list = response.data['data'] as List;
    return list.map((item) => ExerciseItem.fromJson(item)).toList();
  }

  // --- Rutinitas Latihan ---
  Future<List<WorkoutRoutineItem>> getRoutines() async {
    final response = await apiClient.get('/workouts/routines');
    final list = response.data['data'] as List;
    return list.map((item) => WorkoutRoutineItem.fromJson(item)).toList();
  }

  Future<WorkoutRoutineItem> createRoutine({
    required String title,
    String? description,
    int daysPerWeek = 3,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final response = await apiClient.post(
      '/workouts/routines',
      data: {
        'title': title,
        'description': description,
        'daysPerWeek': daysPerWeek,
        'exercises': exercises,
      },
    );
    return WorkoutRoutineItem.fromJson(response.data['data']);
  }

  // --- Sesi Workout & Sets ---
  Future<WorkoutSessionItem> startSession({required String title, String? routineId}) async {
    final response = await apiClient.post(
      '/workouts/sessions',
      data: {
        'title': title,
        'routineId': ?routineId,
      },
    );
    return WorkoutSessionItem.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> logSet({
    required String sessionId,
    required String exerciseId,
    required int setNumber,
    required int reps,
    required double weightKg,
    double? rpe,
  }) async {
    final response = await apiClient.post(
      '/workouts/sessions/$sessionId/sets',
      data: {
        'exerciseId': exerciseId,
        'setNumber': setNumber,
        'reps': reps,
        'weightKg': weightKg,
        'rpe': ?rpe,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<WorkoutSessionItem> finishSession({required String sessionId, String? notes}) async {
    final response = await apiClient.put(
      '/workouts/sessions/$sessionId/finish',
      data: {
        'notes': ?notes,
      },
    );
    return WorkoutSessionItem.fromJson(response.data['data']);
  }

  Future<List<WorkoutSessionItem>> getUserSessions() async {
    final response = await apiClient.get('/workouts/sessions');
    final list = response.data['data'] as List;
    return list.map((item) => WorkoutSessionItem.fromJson(item)).toList();
  }

  Future<List<PersonalRecordItem>> getPersonalRecords() async {
    final response = await apiClient.get('/workouts/personal-records');
    final list = response.data['data'] as List;
    return list.map((item) => PersonalRecordItem.fromJson(item)).toList();
  }

  // --- AI Workout Generator ---
  Future<Map<String, dynamic>> generateAIWorkout({
    String goal = 'hypertrophy',
    int daysPerWeek = 3,
    String equipment = 'gym',
  }) async {
    final response = await apiClient.post(
      '/workouts/ai-generate',
      data: {
        'goal': goal,
        'daysPerWeek': daysPerWeek,
        'equipment': equipment,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  // --- Progres Tubuh & Ukuran (F12) ---
  Future<BodyProgressSummary> getBodyMeasurements() async {
    final response = await apiClient.get('/body/measurements');
    return BodyProgressSummary.fromJson(response.data['data']);
  }

  Future<BodyMeasurementItem> logBodyMeasurement({
    required double weightKg,
    double? waistCm,
    double? chestCm,
    double? hipsCm,
    String? measuredDate,
    String? notes,
  }) async {
    final response = await apiClient.post(
      '/body/measurements',
      data: {
        'weightKg': weightKg,
        'waistCm': ?waistCm,
        'chestCm': ?chestCm,
        'hipsCm': ?hipsCm,
        'measuredDate': ?measuredDate,
        'notes': ?notes,
      },
    );
    return BodyMeasurementItem.fromJson(response.data['data']);
  }
}
