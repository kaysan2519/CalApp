class GamificationProfile {
  final int totalXp;
  final int currentLevel;
  final int currentStreakDays;
  final int dailyXpEarned;
  final int dailyXpCap;
  final int currentLevelBaseXp;
  final int nextLevelXp;
  final double levelProgressRatio;
  final int unlockedAchievementsCount;

  GamificationProfile({
    required this.totalXp,
    required this.currentLevel,
    required this.currentStreakDays,
    required this.dailyXpEarned,
    this.dailyXpCap = 500,
    required this.currentLevelBaseXp,
    required this.nextLevelXp,
    required this.levelProgressRatio,
    required this.unlockedAchievementsCount,
  });

  factory GamificationProfile.fromJson(Map<String, dynamic> json) {
    return GamificationProfile(
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      currentLevel: (json['currentLevel'] as num?)?.toInt() ?? 1,
      currentStreakDays: (json['currentStreakDays'] as num?)?.toInt() ?? 0,
      dailyXpEarned: (json['dailyXpEarned'] as num?)?.toInt() ?? 0,
      dailyXpCap: (json['dailyXpCap'] as num?)?.toInt() ?? 500,
      currentLevelBaseXp: (json['currentLevelBaseXp'] as num?)?.toInt() ?? 0,
      nextLevelXp: (json['nextLevelXp'] as num?)?.toInt() ?? 100,
      levelProgressRatio: (json['levelProgressRatio'] as num?)?.toDouble() ?? 0.0,
      unlockedAchievementsCount: (json['unlockedAchievementsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AchievementItem {
  final String id;
  final String code;
  final String title;
  final String description;
  final String iconName;
  final int xpReward;
  final bool isUnlocked;
  final String? unlockedAt;

  AchievementItem({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.iconName,
    required this.xpReward,
    required this.isUnlocked,
    this.unlockedAt,
  });

  factory AchievementItem.fromJson(Map<String, dynamic> json) {
    return AchievementItem(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconName: json['icon_name'] as String? ?? 'emoji_events',
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 50,
      isUnlocked: json['is_unlocked'] as bool? ?? false,
      unlockedAt: json['unlocked_at'] as String?,
    );
  }
}

class LeaderboardItem {
  final String userId;
  final String displayName;
  final int weekXp;
  final int currentLevel;
  final int rank;

  LeaderboardItem({
    required this.userId,
    required this.displayName,
    required this.weekXp,
    required this.currentLevel,
    required this.rank,
  });

  factory LeaderboardItem.fromJson(Map<String, dynamic> json) {
    return LeaderboardItem(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String? ?? 'Sahabat Cal',
      weekXp: (json['week_xp'] as num?)?.toInt() ?? 0,
      currentLevel: (json['current_level'] as num?)?.toInt() ?? 1,
      rank: (json['rank'] as num?)?.toInt() ?? 1,
    );
  }
}

class ChallengeItem {
  final String id;
  final String title;
  final String description;
  final String challengeType;
  final String targetMetric;
  final int targetValue;
  final int xpReward;
  final int currentProgress;
  final bool isCompleted;

  ChallengeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.challengeType,
    required this.targetMetric,
    required this.targetValue,
    required this.xpReward,
    required this.currentProgress,
    required this.isCompleted,
  });

  factory ChallengeItem.fromJson(Map<String, dynamic> json) {
    return ChallengeItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      challengeType: json['challenge_type'] as String? ?? 'weekly',
      targetMetric: json['target_metric'] as String? ?? 'workout',
      targetValue: (json['target_value'] as num?)?.toInt() ?? 1,
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 35,
      currentProgress: (json['current_progress'] as num?)?.toInt() ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }
}
