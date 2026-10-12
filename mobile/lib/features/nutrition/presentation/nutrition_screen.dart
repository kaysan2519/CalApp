import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/nutrition_models.dart';
import 'ai_coach_screen.dart';
import 'ai_vision_food_sheet.dart';
import 'food_search_modal.dart';
import 'nutrition_state_notifier.dart';
import 'text_food_entry_dialog.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  void _openFoodSearch(BuildContext context, String mealType, String mealTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FoodSearchModal(mealType: mealType, mealTitle: mealTitle),
    );
  }

  void _openAiVision(BuildContext context, String mealType, String mealTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiVisionFoodSheet(mealType: mealType, mealTitle: mealTitle),
    );
  }

  void _openTextEntry(BuildContext context, String mealType, String mealTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TextFoodEntryDialog(mealType: mealType, mealTitle: mealTitle),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionState = ref.watch(nutritionStateProvider);
    final selectedDate = ref.watch(selectedDateProvider);
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
        title: const Text('Nutrisi & Makanan', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
            tooltip: 'Tanya AI Coach',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiCoachScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, size: 20),
            tooltip: 'Pilih Tanggal',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.parse(selectedDate),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                final dateStr = picked.toIso8601String().split('T')[0];
                ref.read(selectedDateProvider.notifier).state = dateStr;
                ref.read(nutritionStateProvider.notifier).loadDailySummary(dateStr);
              }
            },
          ),
        ],
      ),
      body: nutritionState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Gagal memuat catatan nutrisi: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(nutritionStateProvider.notifier).loadDailySummary(selectedDate),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (summary) {
          final target = summary.target;
          final consumed = summary.consumed;
          final remaining = summary.remaining;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Daily Macro Overview Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Dikonsumsi', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  '${consumed.calories} / ${target.calories} kkal',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: remaining.calories > 0
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Sisa ${remaining.calories} kkal',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: remaining.calories > 0 ? AppColors.primary : AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _MacroBar(
                                label: 'Protein',
                                current: consumed.proteinG,
                                target: target.proteinG,
                                color: macroColors.protein,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MacroBar(
                                label: 'Karbo',
                                current: consumed.carbsG,
                                target: target.carbsG,
                                color: macroColors.carbs,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MacroBar(
                                label: 'Lemak',
                                current: consumed.fatG,
                                target: target.fatG,
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

                // 4 Meal Slots
                _MealSlotCard(
                  title: 'Sarapan',
                  icon: Icons.wb_sunny_outlined,
                  slot: summary.meals['breakfast'],
                  onAddFood: () => _openFoodSearch(context, 'breakfast', 'Sarapan'),
                  onAiVision: () => _openAiVision(context, 'breakfast', 'Sarapan'),
                  onAiText: () => _openTextEntry(context, 'breakfast', 'Sarapan'),
                  onDeleteItem: (itemId) => ref.read(nutritionStateProvider.notifier).deleteItem(itemId),
                ),
                const SizedBox(height: 12),

                _MealSlotCard(
                  title: 'Makan Siang',
                  icon: Icons.wb_sunny_rounded,
                  slot: summary.meals['lunch'],
                  onAddFood: () => _openFoodSearch(context, 'lunch', 'Makan Siang'),
                  onAiVision: () => _openAiVision(context, 'lunch', 'Makan Siang'),
                  onAiText: () => _openTextEntry(context, 'lunch', 'Makan Siang'),
                  onDeleteItem: (itemId) => ref.read(nutritionStateProvider.notifier).deleteItem(itemId),
                ),
                const SizedBox(height: 12),

                _MealSlotCard(
                  title: 'Makan Malam',
                  icon: Icons.nightlight_round,
                  slot: summary.meals['dinner'],
                  onAddFood: () => _openFoodSearch(context, 'dinner', 'Makan Malam'),
                  onAiVision: () => _openAiVision(context, 'dinner', 'Makan Malam'),
                  onAiText: () => _openTextEntry(context, 'dinner', 'Makan Malam'),
                  onDeleteItem: (itemId) => ref.read(nutritionStateProvider.notifier).deleteItem(itemId),
                ),
                const SizedBox(height: 12),

                _MealSlotCard(
                  title: 'Camilan',
                  icon: Icons.local_cafe_outlined,
                  slot: summary.meals['snack'],
                  onAddFood: () => _openFoodSearch(context, 'snack', 'Camilan'),
                  onAiVision: () => _openAiVision(context, 'snack', 'Camilan'),
                  onAiText: () => _openTextEntry(context, 'snack', 'Camilan'),
                  onDeleteItem: (itemId) => ref.read(nutritionStateProvider.notifier).deleteItem(itemId),
                ),

                const SizedBox(height: 16),

                // Water Tracker
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.water_drop_rounded, color: AppColors.info),
                                const SizedBox(width: 8),
                                const Text('Konsumsi Air', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            Text(
                              '${consumed.waterMl} / ${target.waterMl} ml',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.info),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: (consumed.waterMl / (target.waterMl > 0 ? target.waterMl : 1)).clamp(0.0, 1.0),
                          backgroundColor: AppColors.info.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation(AppColors.info),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('+250 ml'),
                              onPressed: () => ref.read(nutritionStateProvider.notifier).addWater(250),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('+500 ml'),
                              onPressed: () => ref.read(nutritionStateProvider.notifier).addWater(500),
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _MacroBar extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;

  const _MacroBar({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (current / (target > 0 ? target : 1)).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('${current.round()}/${target.round()}g', style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
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

class _MealSlotCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final MealSlot? slot;
  final VoidCallback onAddFood;
  final VoidCallback onAiVision;
  final VoidCallback onAiText;
  final ValueChanged<String> onDeleteItem;

  const _MealSlotCard({
    required this.title,
    required this.icon,
    required this.slot,
    required this.onAddFood,
    required this.onAiVision,
    required this.onAiText,
    required this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    final items = slot?.items ?? [];
    final totalCalories = slot?.totalCalories ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(
                  '${totalCalories.round()} kkal',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.calories),
                ),
              ],
            ),
            if (items.isNotEmpty) ...[
              const Divider(height: 20),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.foodName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(
                              '${item.servingQty}x ${item.servingUnit} • P: ${item.proteinG.round()}g C: ${item.carbsG.round()}g F: ${item.fatG.round()}g',
                              style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text('${item.calories.round()} kkal', style: const TextStyle(fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        onPressed: () => onDeleteItem(item.id),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Makanan'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onAddFood,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.camera_alt_outlined, size: 20, color: AppColors.primary),
                  tooltip: 'Foto AI',
                  onPressed: onAiVision,
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  icon: const Icon(Icons.edit_note_rounded, size: 22, color: AppColors.primary),
                  tooltip: 'Teks AI',
                  onPressed: onAiText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
