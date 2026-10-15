import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/gamification_repository.dart';
import '../domain/gamification_models.dart';
import 'achievements_modal.dart';

class RankOverviewScreen extends ConsumerStatefulWidget {
  const RankOverviewScreen({super.key});

  @override
  ConsumerState<RankOverviewScreen> createState() => _RankOverviewScreenState();
}

class _RankOverviewScreenState extends ConsumerState<RankOverviewScreen> {
  GamificationProfile? _profile;
  Map<String, dynamic>? _leaderboard;
  String _period = 'weekly';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repository = ref.read(gamificationRepositoryProvider);
      final results = await Future.wait<Object>([
        repository.getProfile(),
        repository.getLeaderboard(period: _period),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as GamificationProfile;
        _leaderboard = results[1] as Map<String, dynamic>;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Data peringkat belum dapat dimuat. Periksa koneksi lalu coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changePeriod(String period) async {
    if (_period == period) return;
    setState(() => _period = period);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final currentRank = profile?.currentRank;
    final userRank = _leaderboard?['currentUserRank'] as LeaderboardItem?;
    final entries = _leaderboard?['leaderboard'] as List<LeaderboardItem>? ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rank & progres'),
        actions: [
          IconButton(
            tooltip: 'Lencana',
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => AchievementsModal.show(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    children: [
                      _rankCard(profile!, currentRank!),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: _statCard('Total XP', '${profile.totalXp}', Icons.bolt_rounded)),
                        const SizedBox(width: 10),
                        Expanded(child: _statCard('Level', '${profile.currentLevel}', Icons.trending_up_rounded)),
                        const SizedBox(width: 10),
                        Expanded(child: _statCard('Streak', '${profile.currentStreakDays} hari', Icons.local_fire_department_outlined)),
                      ]),
                      const SizedBox(height: 20),
                      _sectionTitle(context, 'Semua rank'),
                      const SizedBox(height: 8),
                      ...profile.ranks.map((rank) => _rankRow(rank, profile.totalXp, currentRank.name)),
                      const SizedBox(height: 20),
                      _sectionTitle(context, 'Leaderboard'),
                      const SizedBox(height: 10),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'weekly', label: Text('Mingguan')),
                          ButtonSegment(value: 'global', label: Text('Global')),
                        ],
                        selected: {_period},
                        onSelectionChanged: (selection) => _changePeriod(selection.first),
                      ),
                      const SizedBox(height: 10),
                      _userStanding(userRank),
                      if (entries.isEmpty)
                        const _EmptyCard(text: 'Belum ada XP pada periode ini. Catat aktivitas yang selesai untuk mulai masuk peringkat.'),
                      ...entries.take(20).map((entry) => _leaderboardRow(entry, userRank?.userId)),
                      const SizedBox(height: 20),
                      _sectionTitle(context, 'Riwayat XP'),
                      const SizedBox(height: 8),
                      if (profile.xpHistory.isEmpty)
                        const _EmptyCard(text: 'Aktivitas yang menghasilkan XP akan muncul di sini.'),
                      ...profile.xpHistory.map(_historyRow),
                      const SizedBox(height: 12),
                      Text('XP diberikan server setelah aktivitas tersimpan dan tercatat.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.darkTextSecondary)),
                    ],
                  ),
                ),
    );
  }

  Widget _rankCard(GamificationProfile profile, RankTier rank) {
    final nextName = rank.nextRankName;
    final progress = rank.progressRatio.clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withValues(alpha: 0.14),
              child: Icon(_rankIcon(rank.iconName), color: AppColors.primary, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(rank.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(rank.description, style: const TextStyle(color: AppColors.darkTextSecondary)),
            ])),
          ]),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(nextName == null ? 'Rank tertinggi tercapai' : 'Progres ke $nextName'),
            Text(nextName == null ? 'MAX' : '${rank.xpToNextRank} XP lagi', style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: nextName == null ? 1 : progress, minHeight: 9)),
          const SizedBox(height: 10),
          Text('${profile.totalXp} XP total · ${profile.dailyXpEarned}/${profile.dailyXpCap} XP hari ini', style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _userStanding(LeaderboardItem? userRank) {
    if (userRank == null || userRank.rank == null) {
      return const _EmptyCard(text: 'Kamu belum masuk peringkat pada periode ini. XP dari aktivitas tersimpan akan memperbarui posisi secara otomatis.');
    }
    final points = userRank.pointsToNextRank;
    return Card(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline_rounded)),
        title: Text('Posisimu #${userRank.rank}', style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(points == null ? 'Skor tertinggi pada periode ini.' : 'Butuh $points XP untuk menyamai posisi di atas.'),
        trailing: Text('${userRank.weekXp} XP', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _leaderboardRow(LeaderboardItem item, String? currentUserId) {
    final isCurrentUser = currentUserId != null && item.userId == currentUserId;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrentUser ? AppColors.primary.withValues(alpha: 0.15) : null,
          child: Text(item.rank?.toString() ?? '—'),
        ),
        title: Text(item.displayName, style: TextStyle(fontWeight: isCurrentUser ? FontWeight.w800 : FontWeight.w600)),
        subtitle: Text('Level ${item.currentLevel}${isCurrentUser ? ' · Kamu' : ''}'),
        trailing: Text('${item.weekXp} XP'),
      ),
    );
  }

  Widget _rankRow(RankTier rank, int totalXp, String currentRank) {
    final unlocked = totalXp >= rank.minXp;
    final isCurrent = rank.name == currentRank;
    return Card(
      margin: const EdgeInsets.only(bottom: 7),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: unlocked ? AppColors.primary.withValues(alpha: 0.13) : Colors.grey.withValues(alpha: 0.13),
          child: Icon(_rankIcon(rank.iconName), color: unlocked ? AppColors.primary : AppColors.darkTextSecondary),
        ),
        title: Text('${rank.name}${isCurrent ? ' · Saat ini' : ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${rank.minXp} XP · ${rank.description}'),
        trailing: Icon(unlocked ? Icons.check_circle_outline_rounded : Icons.lock_outline_rounded, color: unlocked ? AppColors.primary : AppColors.darkTextSecondary),
      ),
    );
  }

  Widget _historyRow(XpHistoryItem item) => Card(
        margin: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          leading: const Icon(Icons.bolt_rounded, color: AppColors.primary),
          title: Text(_eventLabel(item.eventCode)),
          subtitle: Text(_formatDate(item.createdAt)),
          trailing: Text('+${item.xpAmount} XP', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
        ),
      );

  Widget _statCard(String label, String value, IconData icon) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(children: [Icon(icon, color: AppColors.primary), const SizedBox(height: 6), Text(value, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary))]),
        ),
      );

  Widget _sectionTitle(BuildContext context, String title) => Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800));

  Widget _errorView() => Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, size: 42, color: AppColors.warning),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Coba lagi')),
        ]),
      ));

  IconData _rankIcon(String name) => switch (name) {
        'military_tech' => Icons.military_tech_rounded,
        'workspace_premium' => Icons.workspace_premium_rounded,
        'star' => Icons.star_rounded,
        'stars' => Icons.stars_rounded,
        'diamond' => Icons.diamond_outlined,
        _ => Icons.emoji_events_rounded,
      };

  String _eventLabel(String eventCode) => switch (eventCode) {
        'meal_logged' => 'Catatan makan tersimpan',
        'workout_completed' => 'Latihan selesai',
        'community_post' => 'Berbagi di komunitas',
        _ => 'Aktivitas tercatat',
      };

  String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return 'Waktu tidak tersedia';
    String twoDigit(int number) => number.toString().padLeft(2, '0');
    return '${twoDigit(date.day)}/${twoDigit(date.month)}/${date.year} ${twoDigit(date.hour)}:${twoDigit(date.minute)}';
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(text, style: const TextStyle(color: AppColors.darkTextSecondary, height: 1.4))));
}
