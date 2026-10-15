import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/ai_repository.dart';
import '../domain/ai_food_models.dart';
import 'nutrition_state_notifier.dart';

class TextFoodEntryDialog extends ConsumerStatefulWidget {
  final String mealType;
  final String mealTitle;

  const TextFoodEntryDialog({
    super.key,
    required this.mealType,
    required this.mealTitle,
  });

  @override
  ConsumerState<TextFoodEntryDialog> createState() => _TextFoodEntryDialogState();
}

class _TextFoodEntryDialogState extends ConsumerState<TextFoodEntryDialog> {
  final _textController = TextEditingController();
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _errorMessage;
  AiTextFoodResponse? _parsedResponse;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _analyzeText() async {
    final query = _textController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final aiRepo = ref.read(aiRepositoryProvider);
      final response = await aiRepo.parseFoodText(query);
      if (mounted) {
        setState(() {
          _parsedResponse = response;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal menganalisis teks. Pastikan format menyebutkan makanan dan jumlah/satuan.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _saveAllParsedItems() async {
    if (_parsedResponse == null || _parsedResponse!.parsedItems.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(nutritionStateProvider.notifier);
      for (final item in _parsedResponse!.parsedItems) {
        await notifier.logFood(
          mealType: widget.mealType,
          foodName: item.foodName,
          servingQty: item.quantity,
          servingUnit: '${item.rawUnit} (${item.normalizedGrams.round()}g)',
          calories: item.calories,
          proteinG: item.proteinG,
          carbsG: item.carbsG,
          fatG: item.fatG,
          source: item.source,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('${_parsedResponse!.parsedItems.length} makanan berhasil dicatat ke ${widget.mealTitle}!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Gagal menyimpan makanan. Coba lagi.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
                Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Input Teks (${widget.mealTitle})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Text input area
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contoh: nasi 2 centong, ayam bakar 1 potong, dan telur rebus 1 butir...',
                hintStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                filled: true,
                fillColor: AppColors.darkSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),

            // Quick template chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Contoh: ', style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
                  ActionChip(
                    label: const Text('Nasi & Ayam', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      _textController.text = 'nasi putih 2 centong dan ayam bakar 1 potong';
                    },
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    label: const Text('Telur & Tempe', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      _textController.text = 'telur rebus 2 butir dan tempe goreng 2 potong';
                    },
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    label: const Text('Oatmeal & Pisang', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      _textController.text = 'oatmeal 4 sdm dan pisang 1 buah';
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              icon: _isAnalyzing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(_isAnalyzing ? 'Menganalisis Teks...' : 'Analisis Teks AI'),
              onPressed: _isAnalyzing ? null : _analyzeText,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),
            ],

            const SizedBox(height: 16),

            // Parsed results list
            Expanded(
              child: _parsedResponse == null
                  ? Center(
                      child: Text(
                        'Ketik makanan dengan bahasa sehari-hari.\nAI akan mengonversi takaran lokal ke gram dan menghitung nutrisinya.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.darkTextSecondary.withValues(alpha: 0.8), fontSize: 13),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _parsedResponse!.notice,
                                  style: const TextStyle(fontSize: 12, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Hasil Penguraian Makanan:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _parsedResponse!.parsedItems.length,
                            separatorBuilder: (_, _) => const Divider(height: 12),
                            itemBuilder: (context, index) {
                              final item = _parsedResponse!.parsedItems[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.darkSurface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.darkBorder),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.foodName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Porsi: ${item.quantity} ${item.rawUnit} (~${item.normalizedGrams.round()}g)',
                                            style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                                          ),
                                          Text(
                                            'P: ${item.proteinG}g • C: ${item.carbsG}g • F: ${item.fatG}g',
                                            style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${item.calories.round()} kkal',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.calories,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveAllParsedItems,
                          child: _isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : Text('Simpan ${_parsedResponse!.parsedItems.length} Item ke ${widget.mealTitle}'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
