class NotificationPreferencesModel {
  final bool breakfastReminder;
  final String breakfastTime;
  final bool lunchReminder;
  final String lunchTime;
  final bool dinnerReminder;
  final String dinnerTime;
  final bool waterReminder;
  final int waterIntervalHours;
  final bool workoutReminder;
  final String workoutTime;
  final bool gentleTone;

  NotificationPreferencesModel({
    this.breakfastReminder = true,
    this.breakfastTime = '07:30',
    this.lunchReminder = true,
    this.lunchTime = '12:30',
    this.dinnerReminder = true,
    this.dinnerTime = '19:00',
    this.waterReminder = true,
    this.waterIntervalHours = 2,
    this.workoutReminder = true,
    this.workoutTime = '17:00',
    this.gentleTone = true,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      breakfastReminder: json['breakfastReminder'] as bool? ?? true,
      breakfastTime: json['breakfastTime'] as String? ?? '07:30',
      lunchReminder: json['lunchReminder'] as bool? ?? true,
      lunchTime: json['lunchTime'] as String? ?? '12:30',
      dinnerReminder: json['dinnerReminder'] as bool? ?? true,
      dinnerTime: json['dinnerTime'] as String? ?? '19:00',
      waterReminder: json['waterReminder'] as bool? ?? true,
      waterIntervalHours: (json['waterIntervalHours'] as num?)?.toInt() ?? 2,
      workoutReminder: json['workoutReminder'] as bool? ?? true,
      workoutTime: json['workoutTime'] as String? ?? '17:00',
      gentleTone: json['gentleTone'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'breakfastReminder': breakfastReminder,
      'breakfastTime': breakfastTime,
      'lunchReminder': lunchReminder,
      'lunchTime': lunchTime,
      'dinnerReminder': dinnerReminder,
      'dinnerTime': dinnerTime,
      'waterReminder': waterReminder,
      'waterIntervalHours': waterIntervalHours,
      'workoutReminder': workoutReminder,
      'workoutTime': workoutTime,
      'gentleTone': gentleTone,
    };
  }
}

class HealthSensorData {
  final bool isConnected;
  final int stepsToday;
  final double activeCaloriesKcal;
  final String statusMessage;

  HealthSensorData({
    this.isConnected = false,
    this.stepsToday = 0,
    this.activeCaloriesKcal = 0.0,
    this.statusMessage = 'Sensor Health Connect / Apple Health siap dihubungkan.',
  });
}
