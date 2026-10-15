import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/presentation/auth_state_notifier.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _weekdayLabels = <String, String>{
    'monday': 'Senin',
    'tuesday': 'Selasa',
    'wednesday': 'Rabu',
    'thursday': 'Kamis',
    'friday': 'Jumat',
    'saturday': 'Sabtu',
    'sunday': 'Minggu',
  };
  bool _isExporting = false;
  bool _isDeleting = false;

  String _goalLabel(String value) => switch (value) {
        'lose' => 'Menurunkan berat badan',
        'maintain' => 'Menjaga berat badan',
        'gain' => 'Menaikkan berat badan',
        'fitness' => 'Meningkatkan kebugaran',
        'muscle' => 'Membangun otot',
        _ => value,
      };

  String _activityLabel(String value) => switch (value) {
        'sedentary' => 'Lebih banyak duduk',
        'light' => 'Aktivitas ringan',
        'moderate' => 'Cukup aktif',
        'heavy' => 'Aktif',
        'very_heavy' => 'Sangat aktif',
        _ => value,
      };

  String _experienceLabel(String value) => switch (value) {
        'beginner' => 'Pemula',
        'intermediate' => 'Menengah',
        'advanced' => 'Berpengalaman',
        _ => value,
      };

  String _weekdayLabel(String value) => _weekdayLabels[value] ?? value;

  Future<void> _editTargets(NutritionTargets targets, String gender) async {
    final formKey = GlobalKey<FormState>();
    final controllers = <String, TextEditingController>{
      'targetCalories': TextEditingController(text: targets.targetCalories.toString()),
      'targetProteinG': TextEditingController(text: targets.targetProteinG.toStringAsFixed(0)),
      'targetCarbsG': TextEditingController(text: targets.targetCarbsG.toStringAsFixed(0)),
      'targetFatG': TextEditingController(text: targets.targetFatG.toStringAsFixed(0)),
      'targetWaterMl': TextEditingController(text: targets.targetWaterMl.toString()),
    };
    final fields = <(String, String, double, double, bool)>[
      ('targetCalories', 'Kalori (kkal)', gender == 'female' ? 1200 : 1500, 10000, true),
      ('targetProteinG', 'Protein (g)', 20, 500, false),
      ('targetCarbsG', 'Karbohidrat (g)', 20, 1000, false),
      ('targetFatG', 'Lemak (g)', 10, 300, false),
      ('targetWaterMl', 'Air (ml)', 1000, 10000, true),
    ];

    try {
      final updates = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Ubah target harian'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: fields.map((field) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: controllers[field.$1],
                      keyboardType: TextInputType.numberWithOptions(decimal: !field.$5),
                      inputFormatters: field.$5 ? [FilteringTextInputFormatter.digitsOnly] : null,
                      decoration: InputDecoration(labelText: field.$2),
                      validator: (value) {
                        final number = double.tryParse(value?.trim() ?? '');
                        if (number == null || number < field.$3 || number > field.$4) {
                          return 'Masukkan nilai ${field.$3.toInt()}–${field.$4.toInt()}';
                        }
                        return null;
                      },
                    ),
                  )).toList(),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final result = <String, dynamic>{};
                for (final field in fields) {
                  final value = double.parse(controllers[field.$1]!.text.trim());
                  result[field.$1] = field.$5 ? value.toInt() : value;
                }
                Navigator.pop(dialogContext, result);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      );
      if (updates == null) return;
      await ref.read(apiClientProvider).put('/profile/targets', data: updates);
      await ref.read(authStateProvider.notifier).checkAuth();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Target nutrisi berhasil diperbarui.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Target belum tersimpan. Periksa koneksi dan batas nilai lalu coba lagi.')));
      }
    } finally {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
  }

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
        actions: [
          IconButton(
            tooltip: 'Perbarui profil',
            onPressed: () => context.go('/onboarding?edit=true'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
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
                              Text('${user.age} tahun • ${user.weightKg == null ? 'Berat belum diisi' : '${user.weightKg} kg'} • ${user.heightCm == null ? 'Tinggi belum diisi' : '${user.heightCm} cm'}',
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
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _editTargets(targets, user.gender),
                              icon: const Icon(Icons.tune_rounded),
                              label: const Text('Ubah target'),
                            ),
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

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Preferensi personal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        _ProfileDetail(label: 'Tujuan', value: _goalLabel(user.goal)),
                        _ProfileDetail(label: 'Aktivitas harian', value: _activityLabel(user.activityLevel)),
                        _ProfileDetail(label: 'Pengalaman latihan', value: _experienceLabel(user.trainingExperience)),
                        _ProfileDetail(label: 'Frekuensi latihan', value: '${user.trainingDaysPerWeek} hari per minggu'),
                        _ProfileDetail(label: 'Hari latihan', value: user.trainingSchedule.isEmpty ? 'Belum ditentukan' : user.trainingSchedule.map(_weekdayLabel).join(', ')),
                        _ProfileDetail(label: 'Peralatan', value: user.availableEquipment.isEmpty ? 'Belum ditentukan' : user.availableEquipment.join(', ')),
                        _ProfileDetail(label: 'Preferensi makanan', value: user.foodPreferences.isEmpty ? 'Belum ditentukan' : user.foodPreferences.join(', ')),
                        _ProfileDetail(label: 'Alergi', value: user.allergies.isEmpty ? 'Tidak dicatat' : user.allergies.join(', ')),
                        _ProfileDetail(label: 'Pantangan', value: user.dietaryRestrictions.isEmpty ? 'Tidak dicatat' : user.dietaryRestrictions.join(', ')),
                        if (user.targetWeightKg != null) _ProfileDetail(label: 'Target berat', value: '${user.targetWeightKg} kg'),
                        if (user.activityLimitations?.isNotEmpty == true) _ProfileDetail(label: 'Batasan aktivitas', value: user.activityLimitations!),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/onboarding?edit=true'),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Ubah profil'),
                        ),
                        TextButton.icon(
                          onPressed: () => context.go('/recommendations'),
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: const Text('Buat rekomendasi terbaru'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

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

class _ProfileDetail extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 145, child: Text(label, style: const TextStyle(color: AppColors.darkTextSecondary))),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
