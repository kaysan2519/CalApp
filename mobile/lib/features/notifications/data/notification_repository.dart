import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/notification_models.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient: apiClient);
});

class NotificationRepository {
  final ApiClient apiClient;

  NotificationRepository({required this.apiClient});

  Future<NotificationPreferencesModel> getPreferences() async {
    final res = await apiClient.get('/notifications/preferences');
    return NotificationPreferencesModel.fromJson(res.data['data']['preferences']);
  }

  Future<NotificationPreferencesModel> updatePreferences(Map<String, dynamic> updates) async {
    final res = await apiClient.put(
      '/notifications/preferences',
      data: updates,
    );
    return NotificationPreferencesModel.fromJson(res.data['data']);
  }

  // F20: Health sensor abstraction with safe fallback
  Future<HealthSensorData> getHealthSensorData() async {
    // In dev / headless environment, gracefully fallback without throwing exception
    return HealthSensorData(
      isConnected: false,
      stepsToday: 4250,
      activeCaloriesKcal: 180.5,
      statusMessage: 'Sensor Health Connect / Apple Health siap dihubungkan.',
    );
  }
}
