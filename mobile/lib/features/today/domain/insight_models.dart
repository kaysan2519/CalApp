class WeeklyInsightSummary {
  final bool hasData;
  final int daysLogged;
  final int averageCalories;
  final int targetCalories;
  final int calorieDeltaPercent;
  final int proteinAdherencePercent;
  final double totalWorkoutVolumeKg;
  final int averageWaterMl;
  final String narrative;

  WeeklyInsightSummary({
    required this.hasData,
    required this.daysLogged,
    required this.averageCalories,
    required this.targetCalories,
    required this.calorieDeltaPercent,
    required this.proteinAdherencePercent,
    required this.totalWorkoutVolumeKg,
    required this.averageWaterMl,
    required this.narrative,
  });

  factory WeeklyInsightSummary.fromJson(Map<String, dynamic> json) {
    return WeeklyInsightSummary(
      hasData: json['hasData'] as bool? ?? false,
      daysLogged: (json['daysLogged'] as num?)?.toInt() ?? 0,
      averageCalories: (json['averageCalories'] as num?)?.toInt() ?? 0,
      targetCalories: (json['targetCalories'] as num?)?.toInt() ?? 2000,
      calorieDeltaPercent: (json['calorieDeltaPercent'] as num?)?.toInt() ?? 0,
      proteinAdherencePercent: (json['proteinAdherencePercent'] as num?)?.toInt() ?? 0,
      totalWorkoutVolumeKg: (json['totalWorkoutVolumeKg'] as num?)?.toDouble() ?? 0.0,
      averageWaterMl: (json['averageWaterMl'] as num?)?.toInt() ?? 0,
      narrative: json['narrative'] as String? ?? 'Belum ada catatan minggu ini.',
    );
  }
}
