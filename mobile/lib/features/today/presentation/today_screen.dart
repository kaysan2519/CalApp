import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../nutrition/presentation/daily_menu_modal.dart';
import '../../nutrition/presentation/nutrition_state_notifier.dart';
import '../../nutrition/presentation/recipes_screen.dart';
import 'weekly_insight_card.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  final Map<String, bool> _dailyChecklist = {
    'nutrisi': false,
    'hidrasi': false,
    'latihan': false,
  };

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
        title: const Text(
          'Cal',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        actions: [
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Calorie Summary Card
            nutritionState.when(
              loading: () => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target Hari Ini',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.darkTextSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '2.000 kkal',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              error: (_, __) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Target Nutrisi: 2.000 kkal', style: TextStyle(fontWeight: FontWeight.bold)),
                      ElevatedButton(
                        onPressed: () => ref.read(nutritionStateProvider.notifier).loadDailySummary(
                              DateTime.now().toIso8601String().split('T')[0],
                            ),
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (summary) {
                final target = summary.target;
                final consumed = summary.consumed;
                final remaining = summary.remaining;

                return Card(
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
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${consumed.calories} / ${target.calories} kkal',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: remaining.calories > 0
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                remaining.calories > 0
                                    ? 'Sisa ${remaining.calories} kkal'
                                    : 'Lebih ${-remaining.calories} kkal',
                                style: TextStyle(
                                  color: remaining.calories > 0 ? AppColors.primary : AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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

            // Quick Actions (Touch Target >= 48dp)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    icon: const Icon(Icons.restaurant_menu_rounded),
                    label: const Text('Menu AI Hari Ini'),
                    onPressed: () => _openDailyMenu(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                    label: const Text('Resep Sehat', style: TextStyle(color: AppColors.primary)),
                    onPressed: () => _openRecipes(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Hydration Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.water_drop_rounded, color: AppColors.info),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Target Hidrasi',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${nutritionState.asData?.value.consumed.waterMl ?? 0} / 2.500 ml terpenuhi',
                                style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            ref.read(nutritionStateProvider.notifier).addWater(250);
                          },
                          child: const Text('+250 ml'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Planned Workout Routine
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.fitness_center_rounded, color: AppColors.carbs, size: 20),
                            SizedBox(width: 8),
                            Text('Jadwal Latihan Hari Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        Text('Push Day (Dada & Trisep)', style: TextStyle(fontSize: 12, color: AppColors.carbs, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '3 Gerakan Utama: Barbell Bench Press, Incline Dumbbell Press, Triceps Pushdown.',
                      style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.carbs,
                        minimumSize: const Size.fromHeight(42),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                      label: const Text('Mulai Sesi Gym Sekarang', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      onPressed: () => context.go('/workouts'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Daily Checklist Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Checklist Rencana Harian',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Catat semua waktu makan', style: TextStyle(fontSize: 14)),
                      value: _dailyChecklist['nutrisi'],
                      onChanged: (val) {
                        setState(() => _dailyChecklist['nutrisi'] = val ?? false);
                      },
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Minum air minimal 2.000 ml', style: TextStyle(fontSize: 14)),
                      value: _dailyChecklist['hidrasi'],
                      onChanged: (val) {
                        setState(() => _dailyChecklist['hidrasi'] = val ?? false);
                      },
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Selesaikan sesi latihan / 8.000 langkah', style: TextStyle(fontSize: 14)),
                      value: _dailyChecklist['latihan'],
                      onChanged: (val) {
                        setState(() => _dailyChecklist['latihan'] = val ?? false);
                      },
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            Text('$current/$target$unit', style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}
