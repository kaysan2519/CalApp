import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/nutrition_repository.dart';
import '../domain/nutrition_models.dart';
import 'nutrition_state_notifier.dart';

class FoodSearchModal extends ConsumerStatefulWidget {
  final String mealType;
  final String mealTitle;

  const FoodSearchModal({
    super.key,
    required this.mealType,
    required this.mealTitle,
  });

  @override
  ConsumerState<FoodSearchModal> createState() => _FoodSearchModalState();
}

class _FoodSearchModalState extends ConsumerState<FoodSearchModal> {
  final _searchController = TextEditingController();
  List<FoodItem> _results = [];
  bool _isLoading = false;
  FoodItem? _selectedFood;
  double _portionMultiplier = 1.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _performSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      final items = await repo.searchFoods(query: query);
      if (mounted) {
        setState(() => _results = items);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSelectedFood() async {
    if (_selectedFood == null) return;

    setState(() => _isSaving = true);
    try {
      final item = _selectedFood!;
      final scaledCalories = item.calories * _portionMultiplier;
      final scaledProtein = item.proteinG * _portionMultiplier;
      final scaledCarbs = item.carbsG * _portionMultiplier;
      final scaledFat = item.fatG * _portionMultiplier;

      await ref.read(nutritionStateProvider.notifier).logFood(
            mealType: widget.mealType,
            foodItem: item,
            foodName: item.nameId ?? item.name,
            servingQty: _portionMultiplier,
            servingUnit: item.servingUnit,
            calories: scaledCalories,
            proteinG: scaledProtein,
            carbsG: scaledCarbs,
            fatG: scaledFat,
            source: item.source,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('${item.nameId ?? item.name} berhasil dicatat ke ${widget.mealTitle}!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Gagal mencatat makanan. Coba lagi.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkBackground,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Catat ke ${widget.mealTitle}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari makanan (misal: Nasi, Dada Ayam, Tempe)...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
            ),
            onChanged: (val) => _performSearch(val),
          ),
          const SizedBox(height: 12),

          if (_selectedFood != null) ...[
            // Portion Adjuster Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedFood!.nameId ?? _selectedFood!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _selectedFood = null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_selectedFood!.calories * _portionMultiplier).round()} kkal • P: ${(_selectedFood!.proteinG * _portionMultiplier).toStringAsFixed(1)}g • C: ${(_selectedFood!.carbsG * _portionMultiplier).toStringAsFixed(1)}g • F: ${(_selectedFood!.fatG * _portionMultiplier).toStringAsFixed(1)}g',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Porsi: '),
                      for (final p in [0.5, 1.0, 1.5, 2.0])
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ChoiceChip(
                            label: Text('${p}x'),
                            selected: _portionMultiplier == p,
                            onSelected: (selected) {
                              if (selected) setState(() => _portionMultiplier = p);
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveSelectedFood,
                    child: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('Simpan ke Catatan'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(
                        child: Text(
                          'Makanan tidak ditemukan.\nGunakan nama lain atau buat makanan kustom.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.darkTextSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, index) => const Divider(height: 1, color: AppColors.darkBorder),
                        itemBuilder: (context, index) {
                          final food = _results[index];
                          return ListTile(
                            title: Text(food.nameId ?? food.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${food.servingSize.round()} ${food.servingUnit} • P: ${food.proteinG}g • C: ${food.carbsG}g • F: ${food.fatG}g',
                              style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                            ),
                            trailing: Text(
                              '${food.calories.round()} kkal',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.calories),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedFood = food;
                                _portionMultiplier = 1.0;
                              });
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    ),
  );
}
}
