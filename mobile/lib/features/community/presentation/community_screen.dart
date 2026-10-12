import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../gamification/data/gamification_repository.dart';
import '../../gamification/domain/gamification_models.dart';
import '../../gamification/presentation/achievements_modal.dart';
import '../../notifications/presentation/notification_settings_modal.dart';
import '../data/community_repository.dart';
import '../domain/community_models.dart';
import 'create_post_modal.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _refreshCounter = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _triggerRefresh() {
    if (mounted) setState(() => _refreshCounter++);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Komunitas & Peringkat', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('open_notifications_btn'),
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Pengingat & Sensor Sehat',
            onPressed: () => NotificationSettingsModal.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: _triggerRefresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor,
          indicatorWeight: 3,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.dynamic_feed), text: 'Feed Komunitas'),
            Tab(icon: Icon(Icons.group_outlined), text: 'Grup & Teman'),
            Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Peringkat & Misi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedTab(theme),
          _buildGroupsTab(theme),
          _buildLeaderboardTab(theme),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 1: Feed Komunitas & Ringkasan Gamifikasi
  // ----------------------------------------------------
  Widget _buildFeedTab(ThemeData theme) {
    final gamifyRepo = ref.watch(gamificationRepositoryProvider);
    final commRepo = ref.watch(communityRepositoryProvider);

    return RefreshIndicator(
      onRefresh: () async => _triggerRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Gamification Header Profile Card
          FutureBuilder<GamificationProfile>(
            key: ValueKey('gamify_profile_$_refreshCounter'),
            future: gamifyRepo.getProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Memuat level...'),
                  ),
                );
              }

              final profile = snapshot.data;
              final level = profile?.currentLevel ?? 1;
              final xp = profile?.totalXp ?? 0;
              final streak = profile?.currentStreakDays ?? 0;
              final dailyEarned = profile?.dailyXpEarned ?? 0;
              final dailyCap = profile?.dailyXpCap ?? 500;
              final progress = profile?.levelProgressRatio ?? 0.0;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withAlpha(40),
                      theme.primaryColor.withAlpha(15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.primaryColor.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'LEVEL $level',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('$xp XP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                            const SizedBox(width: 4),
                            Text('$streak Hari Streak', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            InkWell(
                              key: const Key('open_achievements_btn'),
                              onTap: () => AchievementsModal.show(context),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.withAlpha(40),
                        valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'XP Hari Ini: $dailyEarned / $dailyCap XP',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          'Level Berikutnya: ${profile?.nextLevelXp ?? 100} XP',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Tombol Buat Postingan
          ElevatedButton.icon(
            key: const Key('open_create_post_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Bagikan Postingan Baru (+15 XP)', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              final created = await CreatePostModal.show(context);
              if (created == true) _triggerRefresh();
            },
          ),
          const SizedBox(height: 20),

          // Feed List
          FutureBuilder<List<PostItem>>(
            key: ValueKey('feed_posts_$_refreshCounter'),
            future: commRepo.getPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Memuat feed komunitas...')));
              }

              if (snapshot.hasError) {
                return Center(child: Text('Gagal memuat feed: ${snapshot.error}'));
              }

              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Belum ada postingan komunitas. Jadilah yang pertama membagikan perjalanan sehat Anda!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return Column(
                children: posts.map((post) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Author & Time
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: theme.primaryColor.withAlpha(40),
                                    foregroundColor: theme.primaryColor,
                                    child: Text(
                                      post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'C',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (post.groupName != null)
                                        Text('di ${post.groupName}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 18),
                                onSelected: (val) {
                                  if (val == 'report') {
                                    commRepo.reportContent(reason: 'Konten tidak pantas', targetPostId: post.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Laporan diterima untuk ditinjau moderasi.')),
                                    );
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'report', child: Text('Laporkan Postingan ⚠️')),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(post.content, style: const TextStyle(height: 1.3)),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 6),
                          // Actions (Kudos & Comments)
                          Row(
                            children: [
                              InkWell(
                                key: Key('kudos_btn_${post.id}'),
                                borderRadius: BorderRadius.circular(8),
                                onTap: () async {
                                  await commRepo.toggleReaction(post.id);
                                  _triggerRefresh();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        post.hasReacted ? Icons.favorite : Icons.favorite_border,
                                        color: post.hasReacted ? Colors.redAccent : Colors.grey,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${post.reactionCount} Kudos',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: post.hasReacted ? Colors.redAccent : Colors.grey,
                                          fontWeight: post.hasReacted ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Row(
                                children: [
                                  const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text('${post.commentCount} Komentar', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 2: Grup & Teman Komunitas
  // ----------------------------------------------------
  Widget _buildGroupsTab(ThemeData theme) {
    final commRepo = ref.watch(communityRepositoryProvider);

    return FutureBuilder<List<GroupItem>>(
      key: ValueKey('groups_future_$_refreshCounter'),
      future: commRepo.getGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Text('Memuat daftar grup...'));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat grup: ${snapshot.error}'));
        }

        final groups = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ElevatedButton.icon(
              key: const Key('create_group_btn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.group_add),
              label: const Text('Buat Grup Komunitas Baru', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                final groupNameCtrl = TextEditingController();
                final created = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Buat Grup Baru'),
                    content: TextField(
                      controller: groupNameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Grup'),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                      ElevatedButton(
                        onPressed: () async {
                          if (groupNameCtrl.text.trim().isNotEmpty) {
                            await commRepo.createGroup(name: groupNameCtrl.text.trim());
                            if (ctx.mounted) Navigator.pop(ctx, true);
                          }
                        },
                        child: const Text('Buat'),
                      ),
                    ],
                  ),
                );
                if (created == true) _triggerRefresh();
              },
            ),
            const SizedBox(height: 16),

            if (groups.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Belum ada grup yang dibuat. Buat grup pertamamu untuk saling menyemangati bersama teman!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...groups.map((group) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.primaryColor.withAlpha(30),
                          foregroundColor: theme.primaryColor,
                          child: const Icon(Icons.people),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              if (group.description != null) ...[
                                const SizedBox(height: 2),
                                Text(group.description!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                              const SizedBox(height: 4),
                              Text('${group.memberCount} Anggota', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: group.isMember ? Colors.grey.withAlpha(40) : theme.primaryColor,
                            foregroundColor: group.isMember ? Colors.white : Colors.white,
                            elevation: 0,
                          ),
                          onPressed: () async {
                            if (group.isMember) {
                              await commRepo.leaveGroup(group.id);
                            } else {
                              await commRepo.joinGroup(group.id);
                            }
                            _triggerRefresh();
                          },
                          child: Text(group.isMember ? 'Keluar' : 'Gabung'),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------
  // TAB 3: Peringkat Leaderboard & Misi Tantangan
  // ----------------------------------------------------
  Widget _buildLeaderboardTab(ThemeData theme) {
    final gamifyRepo = ref.watch(gamificationRepositoryProvider);

    return FutureBuilder<List<dynamic>>(
      key: ValueKey('leaderboard_future_$_refreshCounter'),
      future: Future.wait([
        gamifyRepo.getLeaderboard(),
        gamifyRepo.getChallenges(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Text('Memuat papan peringkat & misi...'));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat: ${snapshot.error}'));
        }

        final lbData = snapshot.data?[0] as Map<String, dynamic>?;
        final leaderboard = (lbData?['leaderboard'] as List<LeaderboardItem>?) ?? [];
        final userRank = lbData?['currentUserRank'] as LeaderboardItem?;
        final challenges = (snapshot.data?[1] as List<ChallengeItem>?) ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User Rank Banner
            if (userRank != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.withAlpha(40), Colors.amber.withAlpha(10)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withAlpha(80)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Peringkat Anda: #${userRank.rank}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('${userRank.weekXp} XP Minggu Ini', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const Chip(label: Text('Asia/Jakarta', style: TextStyle(fontSize: 10))),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Section: Tantangan Mingguan Aktif
            Text('Tantangan Aktif (${challenges.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            ...challenges.map((ch) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(ch.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Chip(label: Text('+${ch.xpReward} XP', style: const TextStyle(fontSize: 11))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(ch.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Section: Top Leaderboard
            Text('Peringkat Mingguan Top', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            ...leaderboard.map((item) {
              final isTop3 = item.rank <= 3;
              Color badgeColor = Colors.grey;
              if (item.rank == 1) badgeColor = Colors.amber;
              if (item.rank == 2) badgeColor = Colors.blueGrey;
              if (item.rank == 3) badgeColor = Colors.brown;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isTop3 ? badgeColor.withAlpha(40) : Colors.grey.withAlpha(20),
                    foregroundColor: isTop3 ? badgeColor : Colors.white,
                    child: Text('#${item.rank}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(item.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Level ${item.currentLevel}', style: const TextStyle(fontSize: 11)),
                  trailing: Text(
                    '${item.weekXp} XP',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor, fontSize: 14),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
