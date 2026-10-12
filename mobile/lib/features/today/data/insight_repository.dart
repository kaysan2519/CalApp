import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/insight_models.dart';

final insightRepositoryProvider = Provider<InsightRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InsightRepository(apiClient: apiClient);
});

class InsightRepository {
  final ApiClient apiClient;

  InsightRepository({required this.apiClient});

  Future<WeeklyInsightSummary> getWeeklyInsights() async {
    final res = await apiClient.get('/insights/weekly');
    return WeeklyInsightSummary.fromJson(res.data['data']);
  }
}
