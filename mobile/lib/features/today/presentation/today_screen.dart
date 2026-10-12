import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifikasi',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profil',
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Calorie Summary Card
            Card(
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
                              'Target Hari Ini',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.darkTextSecondary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '2,150 kkal',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Sisa 1,320 kkal',
                            style: TextStyle(
                              color: AppColors.primary,
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
                            current: 85,
                            target: 140,
                            unit: 'g',
                            color: macroColors.protein,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MacroProgressItem(
                            label: 'Karbo',
                            current: 120,
                            target: 220,
                            unit: 'g',
                            color: macroColors.carbs,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MacroProgressItem(
                            label: 'Lemak',
                            current: 35,
                            target: 65,
                            unit: 'g',
                            color: macroColors.fat,
                          ),
                        ),
                      ],
                    ),
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
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Catat Makan'),
                    onPressed: () {},
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
                    icon: const Icon(Icons.fitness_center_rounded, color: AppColors.primary),
                    label: const Text('Mulai Latihan', style: TextStyle(color: AppColors.primary)),
                    onPressed: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Hydration Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.water_drop_rounded, color: AppColors.info),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hidrasi Hari Ini',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '1,250 / 2,500 ml (50%)',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.darkTextSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.info, size: 28),
                      tooltip: 'Tambah 250ml Air',
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
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
    final progress = (current / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('$current/$target$unit',
                style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }
}
