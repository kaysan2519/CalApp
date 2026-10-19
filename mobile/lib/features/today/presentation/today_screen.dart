import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state_notifier.dart';
import '../../nutrition/presentation/daily_menu_modal.dart';
import '../../nutrition/presentation/nutrition_state_notifier.dart';
import '../../nutrition/presentation/recipes_screen.dart';
import 'master_action_hub_modal.dart';
import 'weekly_insight_card.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  void _openDailyMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DailyMenuModal(),
    );
  }

  void _openRecipes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecipesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nutritionState = ref.watch(nutritionStateProvider);
    final authState = ref.watch(authStateProvider);
    final summary = nutritionState.asData?.value;
    final targetWaterMl = summary?.target.waterMl ?? 0;
    final consumedWaterMl = summary?.consumed.waterMl ?? 0;
    final todayKey = const [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ][DateTime.now().weekday - 1];
    final macroColors = Theme.of(context).extension<CalMacroColors>() ??
        const CalMacroColors(
          protein: AppColors.protein,
          carbs: AppColors.carbs,
          fat: AppColors.fat,
          calories: AppColors.calories,
          cardBorder: AppColors.darkBorder,
        );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Cal',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 24),
            tooltip: 'Pusat Aksi Cepat (+)',
            onPressed: () => MasterActionHubModal.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined, color: AppColors.primary),
            tooltip: 'Rank & progres',
            onPressed: () => context.push('/rank'),
          ),
          IconButton(
            icon: const Icon(Icons.restaurant_menu_rounded, color: AppColors.primary),
            tooltip: 'Menu Harian AI',
            onPressed: () => _openDailyMenu(context),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: 'Katalog Resep',
            onPressed: () => _openRecipes(context),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profil',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Calorie Summary Hero Card
            nutritionState.when(
              loading: () => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Memuat target nutrisi', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Mengambil ringkasan akun dari server.',
                            style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              error: (_, _) => Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('Ringkasan nutrisi belum dapat dimuat.',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton(
                      onPressed: () => ref.read(nutritionStateProvider.notifier).loadDailySummary(
                            DateTime.now().toIso8601String().split('T')[0],
                          ),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
              data: (summary) {
                final target = summary.target;
                final consumed = summary.consumed;
                final remaining = summary.remaining;
                final calorieProgress =
                    target.calories > 0 ? (consumed.calories / target.calories).clamp(0.0, 1.0) : 0.0;

                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF141F30)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Target Nutrisi Hari Ini',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        color: AppColors.darkTextSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${consumed.calories} / ${target.calories} kkal',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: remaining.calories > 0
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: remaining.calories > 0
                                      ? AppColors.primary.withValues(alpha: 0.3)
                                      : AppColors.warning.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                remaining.calories > 0
                                    ? 'Sisa ${remaining.calories} kkal'
                                    : 'Lebih ${-remaining.calories} kkal',
                                style: TextStyle(
                                  color: remaining.calories > 0 ? AppColors.primary : AppColors.warning,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Main Calorie Linear Progress
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: calorieProgress,
                            minHeight: 10,
                            backgroundColor: AppColors.darkSurface,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Macro Progress Bars
                        Row(
                          children: [
                            Expanded(
                              child: _MacroProgressItem(
                                label: 'Protein',
                                current: consumed.proteinG.round(),
                                target: target.proteinG.round(),
                                unit: 'g',
                                color: macroColors.protein,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MacroProgressItem(
                                label: 'Karbo',
                                current: consumed.carbsG.round(),
                                target: target.carbsG.round(),
                                unit: 'g',
                                color: macroColors.carbs,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MacroProgressItem(
                                label: 'Lemak',
                                current: consumed.fatG.round(),
                                target: target.fatG.round(),
                                unit: 'g',
                                color: macroColors.fat,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Master Action Hub Banner
            InkWell(
              onTap: () => MasterActionHubModal.show(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF13221C), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_a_photo_rounded, color: Colors.black, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pusat Aksi Cepat (+)',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pindai Kamera AI, Barcode, & Katalog Gerakan Dunia',
                            style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Actions (Touch Target >= 48dp)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.restaurant_menu_rounded, size: 20),
                    label: const Text('Menu AI Hari Ini'),
                    onPressed: () => _openDailyMenu(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 20),
                    label: const Text('Resep Sehat',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    onPressed: () => _openRecipes(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Hydration Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.water_drop_rounded, color: Color(0xFF38BDF8), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Target Hidrasi',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            summary == null
                                ? 'Data hidrasi belum tersedia.'
                                : targetWaterMl > 0
                                    ? '$consumedWaterMl / $targetWaterMl ml terpenuhi'
                                    : 'Target hidrasi belum diatur di profil.',
                            style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                        side: const BorderSide(color: Color(0xFF38BDF8)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: summary == null
                          ? null
                          : () => ref.read(nutritionStateProvider.notifier).addWater(250),
                      child: const Text('+250 ml', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Planned Workout Routine
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.carbs.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fitness_center_rounded, color: AppColors.carbs, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Jadwal Latihan Hari Ini',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      authState.when(
                        data: (user) {
                          if (user == null) return 'Masuk untuk melihat jadwal latihan.';
                          if (user.trainingSchedule.isEmpty) {
                            return 'Jadwal belum diatur. Tambahkan hari latihan di profil.';
                          }
                          if (user.trainingSchedule.contains(todayKey)) {
                            return 'Hari ini termasuk jadwal latihan pilihanmu.';
                          }
                          return 'Tidak ada latihan terjadwal hari ini. Hari istirahat juga bagian dari progres.';
                        },
                        loading: () => 'Memuat jadwal dari profil…',
                        error: (_, _) => 'Jadwal latihan belum dapat dimuat.',
                      ),
                      style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.carbs,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                      label: const Text(
                        'Mulai Sesi Gym Sekarang',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
                      ),
                      onPressed: () => context.go('/workouts'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            const WeeklyInsightCard(),
          ],
        ),
      ),
    );
  }
}

class _MacroProgressItem extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final String unit;
  final Color color;

  const _MacroProgressItem({
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: color),
              ),
              Text(
                '$current/$target$unit',
                style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 10.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
