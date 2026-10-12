import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe_models.dart';
import 'nutrition_state_notifier.dart';

class DailyMenuModal extends ConsumerStatefulWidget {
  const DailyMenuModal({super.key});

  @override
  ConsumerState<DailyMenuModal> createState() => _DailyMenuModalState();
}

class _DailyMenuModalState extends ConsumerState<DailyMenuModal> {
  bool _isLoading = false;
  bool _isApplying = false;
  String? _errorMessage;
  DailyMenuPlan? _plan;

  @override
  void initState() {
    super.initState();
    _generatePlan();
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(recipeRepositoryProvider);
      final today = ref.read(selectedDateProvider);
      final result = await repo.generateDailyMenu(date: today);
      if (mounted) {
        setState(() => _plan = result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Gagal menghasilkan menu harian.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _applyAllMeals() async {
    if (_plan == null) return;

    setState(() => _isApplying = true);
    try {
      final repo = ref.read(recipeRepositoryProvider);
      final today = ref.read(selectedDateProvider);

      for (final meal in _plan!.meals) {
        await repo.logRecipeToMeal(
          recipeId: meal.recipeId,
          mealType: meal.mealType,
          servings: meal.servings,
          logDate: today,
        );
      }

      await ref.read(nutritionStateProvider.notifier).loadDailySummary(today);

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        messenger.showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('Seluruh rekomendasi menu berhasil diterapkan ke catatan hari ini!'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Gagal menerapkan menu ke catatan.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkBackground,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.restaurant_menu_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Menu Harian AI',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isLoading) ...[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Menyusun menu seimbang dari 20 resep Nusantara...', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('Menyesuaikan alokasi kalori & makro harian', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ] else if (_errorMessage != null) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                      const SizedBox(height: 8),
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _generatePlan, child: const Text('Coba Lagi')),
                    ],
                  ),
                ),
              ),
            ] else if (_plan != null) ...[
              // Summary card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: ${_plan!.totalPlannedCalories.round()} / ${_plan!.targetCalories} kkal',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Toleransi ${_plan!.variancePercent > 0 ? "+" : ""}${_plan!.variancePercent}%',
                            style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _plan!.notice,
                      style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.separated(
                  itemCount: _plan!.meals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final meal = _plan!.meals[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(meal.mealTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              Text('${meal.calories.round()} kkal', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.calories)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(meal.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            '${meal.servings}x porsi • P: ${meal.proteinG.round()}g C: ${meal.carbsG.round()}g F: ${meal.fatG.round()}g',
                            style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                          ),
                          if (meal.alternatives.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: [
                                const Text('Opsi lain: ', style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
                                for (final alt in meal.alternatives)
                                  Text(
                                    '${alt["title"]}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary, decoration: TextDecoration.underline),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Acak Ulang'),
                    onPressed: _generatePlan,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: _isApplying
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text('Terapkan ke Catatan'),
                      onPressed: _isApplying ? null : _applyAllMeals,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
