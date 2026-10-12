import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_state_notifier.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isExporting = false;
  bool _isDeleting = false;

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final data = await repository.exportData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('Data berhasil diekspor (${data.keys.length} kategori). Arsip tersimpan.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Gagal mengekspor data akun.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun Permanen?'),
        content: const Text(
          'Tindakan ini tidak dapat dibatalkan. Seluruh data nutrisi, latihan, dan profil Anda akan dihapus permanen dari server kami.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Hapus Akun'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      try {
        await ref.read(authStateProvider.notifier).deleteAccount();
        if (mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.error,
              content: Text('Gagal menghapus akun. Coba lagi.'),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Terjadi kesalahan memuat profil: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(authStateProvider.notifier).checkAuth(),
                child: const Text('Muat Ulang'),
              ),
            ],
          ),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Masuk ke Akun'),
              ),
            );
          }

          final targets = user.nutritionTargets;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(user.email, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('${user.age} tahun • ${user.weightKg ?? 0} kg • ${user.heightCm ?? 0} cm',
                                  style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Nutrition Targets Card
                if (targets != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Target Nutrisi Harian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: targets.isManual ? AppColors.warning.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  targets.isManual ? 'Kustom Manual' : 'Rumus Mifflin-St Jeor',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: targets.isManual ? AppColors.warning : AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _TargetStat(label: 'Kalori', value: '${targets.targetCalories} kkal', color: AppColors.calories),
                              _TargetStat(label: 'Protein', value: '${targets.targetProteinG.round()}g', color: AppColors.protein),
                              _TargetStat(label: 'Karbo', value: '${targets.targetCarbsG.round()}g', color: AppColors.carbs),
                              _TargetStat(label: 'Lemak', value: '${targets.targetFatG.round()}g', color: AppColors.fat),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Account Actions (F22: Ekspor & Hapus Akun)
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.download_rounded, color: AppColors.info),
                        title: const Text('Ekspor Data Pribadi (JSON)'),
                        subtitle: const Text('Unduh salinan riwayat makanan & latihan Anda'),
                        trailing: _isExporting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.chevron_right_rounded),
                        onTap: _isExporting ? null : _handleExport,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: AppColors.warning),
                        title: const Text('Keluar (Logout)'),
                        onTap: () async {
                          await ref.read(authStateProvider.notifier).logout();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                        title: const Text('Hapus Akun Permanen', style: TextStyle(color: AppColors.error)),
                        subtitle: const Text('Hapus data akun & privasi sesuai UU PDP'),
                        trailing: _isDeleting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.chevron_right_rounded, color: AppColors.error),
                        onTap: _isDeleting ? null : _handleDeleteAccount,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TargetStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TargetStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
      ],
    );
  }
}
