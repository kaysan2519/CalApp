import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/gamification_models.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GamificationRepository(apiClient: apiClient);
});

class GamificationRepository {
  final ApiClient apiClient;

  GamificationRepository({required this.apiClient});

  Future<GamificationProfile> getProfile() async {
    final res = await apiClient.get('/gamification/profile');
    return GamificationProfile.fromJson(res.data['data']);
  }

  Future<List<AchievementItem>> getAchievements() async {
    final res = await apiClient.get('/gamification/achievements');
    final list = res.data['data'] as List;
    return list.map((e) => AchievementItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getLeaderboard({int limit = 50, String period = 'weekly'}) async {
    final res = await apiClient.get('/gamification/leaderboard', queryParameters: {'limit': limit, 'period': period});
    final data = res.data['data'];
    final rawList = data['leaderboard'] as List;
    final items = rawList.map((e) => LeaderboardItem.fromJson(e as Map<String, dynamic>)).toList();
    LeaderboardItem? userRank;
    if (data['currentUserRank'] != null) {
      userRank = LeaderboardItem.fromJson(data['currentUserRank']);
    }
    return {
      'leaderboard': items,
      'currentUserRank': userRank,
      'canonicalTimezone': data['canonicalTimezone'] ?? 'Asia/Jakarta',
      'period': data['period'] ?? period,
    };
  }

  Future<List<ChallengeItem>> getChallenges() async {
    final res = await apiClient.get('/gamification/challenges');
    final list = res.data['data'] as List;
    return list.map((e) => ChallengeItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> awardXp({
    required String eventCode,
    required String activityId,
  }) async {
    final res = await apiClient.post(
      '/gamification/award-xp',
      data: {
        'eventCode': eventCode,
        'activityId': activityId,
      },
    );
    return res.data['data'] as Map<String, dynamic>;
  }
}
