class ExerciseItem {
  final String id;
  final String name;
  final String targetMuscle;
  final String category;
  final String equipment;
  final String? instructions;

  ExerciseItem({
    required this.id,
    required this.name,
    required this.targetMuscle,
    required this.category,
    required this.equipment,
    this.instructions,
  });

  factory ExerciseItem.fromJson(Map<String, dynamic> json) {
    return ExerciseItem(
      id: json['id'] as String,
      name: json['name'] as String,
      targetMuscle: json['target_muscle'] as String? ?? 'Full Body',
      category: json['category'] as String? ?? 'barbell',
      equipment: json['equipment'] as String? ?? 'Barbell',
      instructions: json['instructions'] as String?,
    );
  }
}

class WorkoutSetItem {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final int setNumber;
  final int reps;
  final double weightKg;
  final double? rpe;
  final bool isPR;

  WorkoutSetItem({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    required this.reps,
    required this.weightKg,
    this.rpe,
    this.isPR = false,
  });

  factory WorkoutSetItem.fromJson(Map<String, dynamic> json) {
    return WorkoutSetItem(
      id: json['id'] as String? ?? '',
      exerciseId: json['exerciseId'] ?? json['exercise_id'] ?? '',
      exerciseName: json['exerciseName'] ?? json['exercise_name'] ?? 'Latihan',
      setNumber: (json['setNumber'] ?? json['set_number'] as num?)?.toInt() ?? 1,
      reps: (json['reps'] as num?)?.toInt() ?? 10,
      weightKg: (json['weightKg'] ?? json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      rpe: (json['rpe'] as num?)?.toDouble(),
      isPR: (json['isPR'] ?? json['is_personal_record'] as bool?) ?? false,
    );
  }
}

class WorkoutSessionItem {
  final String id;
  final String? routineId;
  final String title;
  final String startedAt;
  final String? completedAt;
  final String status;
  final int durationSeconds;
  final double totalVolumeKg;
  final String? notes;
  final List<WorkoutSetItem> sets;

  WorkoutSessionItem({
    required this.id,
    this.routineId,
    required this.title,
    required this.startedAt,
    this.completedAt,
    this.status = 'in_progress',
    this.durationSeconds = 0,
    this.totalVolumeKg = 0.0,
    this.notes,
    this.sets = const [],
  });

  factory WorkoutSessionItem.fromJson(Map<String, dynamic> json) {
    final rawSets = json['sets'] as List? ?? [];
    return WorkoutSessionItem(
      id: json['id'] as String,
      routineId: json['routine_id'] as String?,
      title: json['title'] as String? ?? 'Sesi Latihan',
      startedAt: json['started_at'] as String? ?? DateTime.now().toIso8601String(),
      completedAt: json['completed_at'] as String?,
      status: json['status'] as String? ?? 'in_progress',
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      totalVolumeKg: (json['total_volume_kg'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      sets: rawSets.map((e) => WorkoutSetItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class RoutineExerciseItem {
  final String id;
  final String exerciseId;
  final String name;
  final String targetMuscle;
  final String equipment;
  final int orderIndex;
  final int targetSets;
  final int targetReps;
  final int restSeconds;

  RoutineExerciseItem({
    required this.id,
    required this.exerciseId,
    required this.name,
    required this.targetMuscle,
    required this.equipment,
    required this.orderIndex,
    required this.targetSets,
    required this.targetReps,
    required this.restSeconds,
  });

  factory RoutineExerciseItem.fromJson(Map<String, dynamic> json) {
    return RoutineExerciseItem(
      id: json['id'] as String? ?? '',
      exerciseId: json['exerciseId'] ?? json['exercise_id'] ?? '',
      name: json['name'] as String? ?? 'Latihan',
      targetMuscle: json['targetMuscle'] ?? json['target_muscle'] ?? '',
      equipment: json['equipment'] as String? ?? '',
      orderIndex: (json['orderIndex'] ?? json['order_index'] as num?)?.toInt() ?? 0,
      targetSets: (json['targetSets'] ?? json['target_sets'] as num?)?.toInt() ?? 3,
      targetReps: (json['targetReps'] ?? json['target_reps'] as num?)?.toInt() ?? 10,
      restSeconds: (json['restSeconds'] ?? json['rest_seconds'] as num?)?.toInt() ?? 90,
    );
  }
}

class WorkoutRoutineItem {
  final String id;
  final String title;
  final String? description;
  final int daysPerWeek;
  final bool isTemplate;
  final List<RoutineExerciseItem> exercises;

  WorkoutRoutineItem({
    required this.id,
    required this.title,
    this.description,
    this.daysPerWeek = 3,
    this.isTemplate = false,
    this.exercises = const [],
  });

  factory WorkoutRoutineItem.fromJson(Map<String, dynamic> json) {
    final rawEx = json['exercises'] as List? ?? [];
    return WorkoutRoutineItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      daysPerWeek: (json['days_per_week'] as num?)?.toInt() ?? 3,
      isTemplate: json['is_template'] as bool? ?? false,
      exercises: rawEx.map((e) => RoutineExerciseItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class PersonalRecordItem {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final String targetMuscle;
  final double maxWeightKg;
  final int maxReps;
  final double estimated1RM;
  final String achievedAt;

  PersonalRecordItem({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.targetMuscle,
    required this.maxWeightKg,
    required this.maxReps,
    required this.estimated1RM,
    required this.achievedAt,
  });

  factory PersonalRecordItem.fromJson(Map<String, dynamic> json) {
    return PersonalRecordItem(
      id: json['id'] as String,
      exerciseId: json['exercise_id'] as String,
      exerciseName: json['exercise_name'] as String? ?? 'Latihan',
      targetMuscle: json['target_muscle'] as String? ?? '',
      maxWeightKg: (json['max_weight_kg'] as num?)?.toDouble() ?? 0.0,
      maxReps: (json['max_reps'] as num?)?.toInt() ?? 1,
      estimated1RM: (json['estimated_1rm'] as num?)?.toDouble() ?? 0.0,
      achievedAt: json['achieved_at'] as String? ?? '',
    );
  }
}

class BodyMeasurementItem {
  final String id;
  final String measuredDate;
  final double weightKg;
  final double? waistCm;
  final double? chestCm;
  final double? hipsCm;
  final String? notes;

  BodyMeasurementItem({
    required this.id,
    required this.measuredDate,
    required this.weightKg,
    this.waistCm,
    this.chestCm,
    this.hipsCm,
    this.notes,
  });

  factory BodyMeasurementItem.fromJson(Map<String, dynamic> json) {
    return BodyMeasurementItem(
      id: json['id'] as String,
      measuredDate: json['measured_date'] as String,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      waistCm: (json['waist_cm'] as num?)?.toDouble(),
      chestCm: (json['chest_cm'] as num?)?.toDouble(),
      hipsCm: (json['hips_cm'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }
}

class BodyProgressSummary {
  final List<BodyMeasurementItem> history;
  final double? latestWeight;
  final double weightDelta;
  final int totalEntries;

  BodyProgressSummary({
    required this.history,
    this.latestWeight,
    required this.weightDelta,
    required this.totalEntries,
  });

  factory BodyProgressSummary.fromJson(Map<String, dynamic> json) {
    final rawHist = json['history'] as List? ?? [];
    return BodyProgressSummary(
      history: rawHist.map((e) => BodyMeasurementItem.fromJson(e as Map<String, dynamic>)).toList(),
      latestWeight: (json['latestWeight'] as num?)?.toDouble(),
      weightDelta: (json['weightDelta'] as num?)?.toDouble() ?? 0.0,
      totalEntries: (json['totalEntries'] as num?)?.toInt() ?? 0,
    );
  }
}
