import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe_models.dart';
import 'nutrition_state_notifier.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  final _searchController = TextEditingController();
  String _selectedTag = 'Semua';
  List<RecipeItem> _recipes = [];
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _tags = [
    'Semua',
    'Tinggi Protein',
    'Rendah Lemak',
    'Vegetarian',
    'Tinggi Serat',
  ];

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecipes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(recipeRepositoryProvider);
      final tagFilter = _selectedTag == 'Semua' ? null : _selectedTag;
      final results = await repo.getRecipes(
        query: _searchController.text.trim(),
        tag: tagFilter,
      );
      if (mounted) {
        setState(() => _recipes = results);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Gagal memuat katalog resep.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openRecipeDetail(RecipeItem recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecipeDetailSheet(recipe: recipe),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resep Sehat Nusantara', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari resep (misal: Pepes, Ayam, Sup, Tempe)...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _fetchRecipes();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _fetchRecipes(),
            ),
          ),

          // Tag chips carousel
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: _tags.map((tag) {
                final isSelected = _selectedTag == tag;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedTag = tag);
                      _fetchRecipes();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                            const SizedBox(height: 8),
                            Text(_errorMessage!),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _fetchRecipes, child: const Text('Coba Lagi')),
                          ],
                        ),
                      )
                    : _recipes.isEmpty
                        ? const Center(
                            child: Text(
                              'Tidak ada resep yang sesuai kriteria.',
                              style: TextStyle(color: AppColors.darkTextSecondary),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _recipes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final recipe = _recipes[index];
                              return Card(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _openRecipeDetail(recipe),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                recipe.title,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ),
                                            Text(
                                              '${recipe.caloriesPerServing.round()} kkal',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.calories),
                                            ),
                                          ],
                                        ),
                                        if (recipe.description != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            recipe.description!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Icon(Icons.timer_outlined, size: 14, color: AppColors.darkTextSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${recipe.prepTimeMin + recipe.cookTimeMin} mnt',
                                              style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'P: ${recipe.proteinPerServing.round()}g • C: ${recipe.carbsPerServing.round()}g • F: ${recipe.fatPerServing.round()}g',
                                              style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _RecipeDetailSheet extends ConsumerStatefulWidget {
  final RecipeItem recipe;

  const _RecipeDetailSheet({required this.recipe});

  @override
  ConsumerState<_RecipeDetailSheet> createState() => _RecipeDetailSheetState();
}

class _RecipeDetailSheetState extends ConsumerState<_RecipeDetailSheet> {
  double _servings = 1.0;
  String _selectedMealType = 'lunch';
  bool _isLogging = false;

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final scaledCalories = (recipe.caloriesPerServing * _servings).round();
    final scaledProtein = (recipe.proteinPerServing * _servings).toStringAsFixed(1);
    final scaledCarbs = (recipe.carbsPerServing * _servings).toStringAsFixed(1);
    final scaledFat = (recipe.fatPerServing * _servings).toStringAsFixed(1);

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
                Expanded(
                  child: Text(
                    recipe.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Portion Adjuster Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jumlah Porsi:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [0.5, 1.0, 1.5, 2.0].map((s) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('${s}x'),
                                selected: _servings == s,
                                onSelected: (selected) {
                                  if (selected) setState(() => _servings = s);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Kalori', style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
                          Text('$scaledCalories kkal', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.calories)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Protein', style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
                          Text('${scaledProtein}g', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.protein)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Karbo', style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
                          Text('${scaledCarbs}g', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.carbs)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Lemak', style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
                          Text('${scaledFat}g', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.fat)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: [
                  if (recipe.ingredients.isNotEmpty) ...[
                    const Text('Bahan-Bahan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    for (final ing in recipe.ingredients)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('• ${ing.name}'),
                            if (ing.qty != null)
                              Text(
                                '${(ing.qty! * _servings).toStringAsFixed(1)} ${ing.unit ?? ""}',
                                style: const TextStyle(color: AppColors.darkTextSecondary),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

                  if (recipe.instructions.isNotEmpty) ...[
                    const Text('Langkah Memasak:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    for (var i = 0; i < recipe.instructions.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: AppColors.primary,
                              child: Text('${i + 1}', style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(recipe.instructions[i], style: const TextStyle(fontSize: 13, height: 1.4))),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMealType,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'breakfast', child: Text('Sarapan')),
                      DropdownMenuItem(value: 'lunch', child: Text('Makan Siang')),
                      DropdownMenuItem(value: 'dinner', child: Text('Makan Malam')),
                      DropdownMenuItem(value: 'snack', child: Text('Camilan')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedMealType = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLogging
                      ? null
                      : () async {
                          setState(() => _isLogging = true);
                          try {
                            final repo = ref.read(recipeRepositoryProvider);
                            final today = ref.read(selectedDateProvider);
                            await repo.logRecipeToMeal(
                              recipeId: recipe.id,
                              mealType: _selectedMealType,
                              servings: _servings,
                              logDate: today,
                            );
                            await ref.read(nutritionStateProvider.notifier).loadDailySummary(today);
                            if (mounted) {
                              final messenger = ScaffoldMessenger.of(context);
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                              messenger.showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.primary,
                                  content: Text('${recipe.title} (${_servings}x porsi) berhasil dicatat!'),
                                ),
                              );
                            }
                          } catch (_) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(backgroundColor: AppColors.error, content: Text('Gagal mencatat resep ke log.')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isLogging = false);
                          }
                        },
                  child: _isLogging
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Catat ke Buku Makan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
