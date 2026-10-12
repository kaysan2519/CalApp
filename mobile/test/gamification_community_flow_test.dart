import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cal/core/network/api_client.dart';
import 'package:cal/core/storage/token_storage.dart';
import 'package:cal/features/gamification/data/gamification_repository.dart';
import 'package:cal/features/gamification/domain/gamification_models.dart';
import 'package:cal/features/community/data/community_repository.dart';
import 'package:cal/features/community/domain/community_models.dart';
import 'package:cal/features/notifications/data/notification_repository.dart';
import 'package:cal/features/notifications/domain/notification_models.dart';
import 'package:cal/features/community/presentation/community_screen.dart';
import 'package:cal/features/community/presentation/create_post_modal.dart';
import 'package:cal/features/gamification/presentation/achievements_modal.dart';
import 'package:cal/features/notifications/presentation/notification_settings_modal.dart';

class FakeGamificationRepository extends GamificationRepository {
  FakeGamificationRepository({required super.apiClient});

  @override
  Future<GamificationProfile> getProfile() async {
    return GamificationProfile(
      totalXp: 550,
      currentLevel: 2,
      currentStreakDays: 3,
      dailyXpEarned: 120,
      dailyXpCap: 500,
      currentLevelBaseXp: 100,
      nextLevelXp: 400,
      levelProgressRatio: 0.45,
      unlockedAchievementsCount: 2,
    );
  }

  @override
  Future<List<AchievementItem>> getAchievements() async {
    return [
      AchievementItem(
        id: 'ach-1',
        code: 'FIRST_MEAL',
        title: 'Langkah Awal',
        description: 'Mencatat makanan pertama di Cal',
        iconName: 'emoji_events',
        xpReward: 50,
        isUnlocked: true,
      ),
      AchievementItem(
        id: 'ach-2',
        code: 'HYDRATION_HERO',
        title: 'Pejuang Hidrasi',
        description: 'Capai target air minum 2000 ml',
        iconName: 'water_drop',
        xpReward: 50,
        isUnlocked: false,
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> getLeaderboard({int limit = 50}) async {
    return {
      'leaderboard': [
        LeaderboardItem(userId: 'u-1', displayName: 'Budi Santoso', weekXp: 450, currentLevel: 3, rank: 1),
        LeaderboardItem(userId: 'u-2', displayName: 'Siti Aminah', weekXp: 320, currentLevel: 2, rank: 2),
      ],
      'currentUserRank': LeaderboardItem(userId: 'my-user-id', displayName: 'Saya', weekXp: 450, currentLevel: 3, rank: 1),
      'canonicalTimezone': 'Asia/Jakarta',
    };
  }

  @override
  Future<List<ChallengeItem>> getChallenges() async {
    return [
      ChallengeItem(
        id: 'ch-1',
        title: 'Konsistensi Protein',
        description: 'Penuhi target protein harian 3 hari beruntun',
        challengeType: 'weekly',
        targetMetric: 'protein',
        targetValue: 3,
        xpReward: 50,
        currentProgress: 2,
        isCompleted: false,
      ),
    ];
  }
}

class FakeCommunityRepository extends CommunityRepository {
  FakeCommunityRepository({required super.apiClient});

  final List<PostItem> fakePosts = [
    PostItem(
      id: 'post-1',
      userId: 'user-budi',
      authorName: 'Budi Santoso',
      content: 'Hari ini berhasil menembus target 100g protein dengan menu tempe dan ayam!',
      createdAt: '2026-10-12T08:00:00Z',
      reactionCount: 4,
      commentCount: 2,
      hasReacted: false,
    ),
  ];

  final List<GroupItem> fakeGroups = [
    GroupItem(
      id: 'grp-1',
      name: 'Pemula Gym Sehat',
      description: 'Komunitas pemula latihan beban dan hidup bugar',
      isPrivate: false,
      memberCount: 25,
      isMember: true,
    ),
  ];

  @override
  Future<List<PostItem>> getPosts({String? groupId, int limit = 20, int offset = 0}) async {
    return fakePosts;
  }

  @override
  Future<PostItem> createPost({required String content, String? groupId, String postType = 'text', Map<String, dynamic>? metadata}) async {
    final newPost = PostItem(
      id: 'post-new-123',
      userId: 'my-user-id',
      authorName: 'Saya',
      content: content,
      createdAt: DateTime.now().toIso8601String(),
    );
    fakePosts.insert(0, newPost);
    return newPost;
  }

  @override
  Future<bool> toggleReaction(String postId, {String reactionType = 'kudos'}) async {
    return true;
  }

  @override
  Future<List<GroupItem>> getGroups() async {
    return fakeGroups;
  }

  @override
  Future<GroupItem> createGroup({required String name, String? description, bool isPrivate = false}) async {
    final g = GroupItem(id: 'grp-new', name: name, description: description, isMember: true);
    fakeGroups.add(g);
    return g;
  }

  @override
  Future<Map<String, dynamic>> reportContent({required String reason, String? targetPostId, String? targetUserId}) async {
    return {'reported': true};
  }
}

class FakeNotificationRepository extends NotificationRepository {
  FakeNotificationRepository({required super.apiClient});

  @override
  Future<NotificationPreferencesModel> getPreferences() async {
    return NotificationPreferencesModel(
      breakfastReminder: true,
      lunchReminder: true,
      dinnerReminder: true,
      waterReminder: true,
      gentleTone: true,
    );
  }

  @override
  Future<HealthSensorData> getHealthSensorData() async {
    return HealthSensorData(
      isConnected: false,
      stepsToday: 6540,
      activeCaloriesKcal: 220.0,
      statusMessage: 'Sensor aktif',
    );
  }
}

void main() {
  late FakeGamificationRepository fakeGamify;
  late FakeCommunityRepository fakeComm;
  late FakeNotificationRepository fakeNotif;

  setUp(() {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    fakeGamify = FakeGamificationRepository(apiClient: apiClient);
    fakeComm = FakeCommunityRepository(apiClient: apiClient);
    fakeNotif = FakeNotificationRepository(apiClient: apiClient);
  });

  Widget createTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        gamificationRepositoryProvider.overrideWithValue(fakeGamify),
        communityRepositoryProvider.overrideWithValue(fakeComm),
        notificationRepositoryProvider.overrideWithValue(fakeNotif),
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

  group('Fase 8 (Gamifikasi, Komunitas & Notifikasi) Widget Tests', () {
    testWidgets('CommunityScreen renders feed, gamification header, and post items', (tester) async {
      await tester.pumpWidget(createTestWidget(const CommunityScreen()));
      await tester.pumpAndSettle();

      // Check App bar
      expect(find.text('Komunitas & Peringkat'), findsOneWidget);
      expect(find.text('Feed Komunitas'), findsOneWidget);
      expect(find.text('Grup & Teman'), findsOneWidget);
      expect(find.text('Peringkat & Misi'), findsOneWidget);

      // Check Gamification profile summary
      expect(find.text('LEVEL 2'), findsOneWidget);
      expect(find.text('550 XP'), findsOneWidget);
      expect(find.text('3 Hari Streak'), findsOneWidget);
      expect(find.textContaining('XP Hari Ini: 120 / 500 XP'), findsOneWidget);

      // Check Post in Feed
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.textContaining('tempe dan ayam'), findsOneWidget);
      expect(find.text('4 Kudos'), findsOneWidget);
    });

    testWidgets('CommunityScreen switch to Grup & Teman and Peringkat tabs', (tester) async {
      await tester.pumpWidget(createTestWidget(const CommunityScreen()));
      await tester.pumpAndSettle();

      // Switch to Tab 2: Grup & Teman
      await tester.tap(find.text('Grup & Teman'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('create_group_btn')), findsOneWidget);
      expect(find.text('Pemula Gym Sehat'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);

      // Switch to Tab 3: Peringkat & Misi
      await tester.tap(find.text('Peringkat & Misi'));
      await tester.pumpAndSettle();

      expect(find.text('Peringkat Anda: #1'), findsOneWidget);
      expect(find.text('Konsistensi Protein'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('450 XP'), findsWidgets);
    });

    testWidgets('CreatePostModal validates text and shares new post', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => CreatePostModal.show(ctx),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Bagikan Cerita ke Komunitas'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('post_content_input')),
        'Semangat latihan squad hari ini, tetap jaga nutrisi!',
      );

      await tester.tap(find.byKey(const Key('submit_post_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Postingan berhasil dibagikan! +15 XP'), findsOneWidget);
    });

    testWidgets('AchievementsModal renders habit badges correctly', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => AchievementsModal.show(ctx),
                child: const Text('Open Achievements'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Achievements'));
      await tester.pumpAndSettle();

      expect(find.text('Lencana Kebiasaan'), findsOneWidget);
      expect(find.text('Langkah Awal'), findsOneWidget);
      expect(find.text('Pejuang Hidrasi'), findsOneWidget);
    });

    testWidgets('NotificationSettingsModal displays reminder toggles and F20 sensor steps', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => NotificationSettingsModal.show(ctx),
                child: const Text('Open Settings'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Pengingat & Sensor Sehat'), findsOneWidget);
      expect(find.textContaining('Langkah Hari Ini: 6540 langkah'), findsOneWidget);
      expect(find.byKey(const Key('toggle_breakfast_reminder')), findsOneWidget);
      expect(find.byKey(const Key('toggle_gentle_tone')), findsOneWidget);
    });
  });
}
