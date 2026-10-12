import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/gamification_repository.dart';
import '../domain/gamification_models.dart';

class AchievementsModal extends ConsumerWidget {
  const AchievementsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AchievementsModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.watch(gamificationRepositoryProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emoji_events, color: Colors.amber, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Lencana Kebiasaan',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Kumpulkan lencana dengan membangun kebiasaan sehat konsisten setiap hari.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<AchievementItem>>(
              future: repo.getAchievements(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Text('Memuat lencana prestasi...'));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Gagal memuat: ${snapshot.error}'));
                }

                final achievements = snapshot.data ?? [];
                if (achievements.isEmpty) {
                  return const Center(child: Text('Belum ada lencana yang terdaftar.'));
                }

                return ListView.builder(
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final ach = achievements[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      color: ach.isUnlocked
                          ? theme.primaryColor.withAlpha(20)
                          : Colors.grey.withAlpha(15),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ach.isUnlocked
                              ? Colors.amber.withAlpha(40)
                              : Colors.grey.withAlpha(40),
                          foregroundColor: ach.isUnlocked ? Colors.amber : Colors.grey,
                          child: Icon(ach.isUnlocked ? Icons.emoji_events : Icons.lock_outline),
                        ),
                        title: Text(
                          ach.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ach.isUnlocked ? Colors.white : Colors.grey[400],
                          ),
                        ),
                        subtitle: Text(
                          ach.description,
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                        trailing: Chip(
                          label: Text('+${ach.xpReward} XP', style: const TextStyle(fontSize: 11)),
                          backgroundColor: ach.isUnlocked
                              ? theme.primaryColor.withAlpha(50)
                              : Colors.grey.withAlpha(30),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
