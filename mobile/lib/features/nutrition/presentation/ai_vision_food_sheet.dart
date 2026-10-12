import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/ai_repository.dart';
import '../domain/ai_food_models.dart';
import 'nutrition_state_notifier.dart';
import 'text_food_entry_dialog.dart';

class AiVisionFoodSheet extends ConsumerStatefulWidget {
  final String mealType;
  final String mealTitle;

  const AiVisionFoodSheet({
    super.key,
    required this.mealType,
    required this.mealTitle,
  });

  @override
  ConsumerState<AiVisionFoodSheet> createState() => _AiVisionFoodSheetState();
}

class _AiVisionFoodSheetState extends ConsumerState<AiVisionFoodSheet> {
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _errorMessage;
  AiVisionFoodResponse? _visionResponse;
  final Map<int, double> _portionScales = {};

  // Mock valid base64 image (1x1 PNG or demo food payload) for platform fallback
  static const String _sampleFoodBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

  Future<void> _scanFoodImage([String? customBase64]) async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _visionResponse = null;
    });

    try {
      final aiRepo = ref.read(aiRepositoryProvider);
      final base64Image = customBase64 ?? _sampleFoodBase64;
      final response = await aiRepo.analyzeFoodVision(base64Image);

      if (mounted) {
        setState(() {
          _visionResponse = response;
          if (response.draftItems.isNotEmpty) {
            for (var i = 0; i < response.draftItems.length; i++) {
              _portionScales[i] = 1.0;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memproses foto makanan. Periksa koneksi dan coba lagi.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _saveAllDraftItems() async {
    if (_visionResponse == null || _visionResponse!.draftItems.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(nutritionStateProvider.notifier);
      for (var i = 0; i < _visionResponse!.draftItems.length; i++) {
        final item = _visionResponse!.draftItems[i];
        final scale = _portionScales[i] ?? 1.0;
        final finalCalories = item.calories * scale;
        final finalProtein = item.proteinG * scale;
        final finalCarbs = item.carbsG * scale;
        final finalFat = item.fatG * scale;
        final finalGrams = (item.estimatedGrams * scale).round();

        await notifier.logFood(
          mealType: widget.mealType,
          foodItemId: item.foodItemId,
          foodName: item.foodName,
          servingQty: scale,
          servingUnit: '${item.portionDescription} (~${finalGrams}g)',
          calories: finalCalories,
          proteinG: finalProtein,
          carbsG: finalCarbs,
          fatG: finalFat,
          source: 'ai_vision',
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('${_visionResponse!.draftItems.length} item tersimpan ke ${widget.mealTitle}!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Gagal menyimpan draf makanan. Coba lagi.'),
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
        height: MediaQuery.of(context).size.height * 0.88,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Pindai Makanan AI (${widget.mealTitle})',
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

            if (_visionResponse == null && !_isAnalyzing) ...[
              // Action card to capture or pick photo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.add_a_photo_outlined, size: 54, color: AppColors.primary),
                    const SizedBox(height: 12),
                    const Text(
                      'Arahkan kamera ke piring makanan Anda',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'AI kami akan mengenali jenis makanan, porsi lokal, dan estimasi nilai nutrisinya.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Ambil Foto / Pindai Sekarang'),
                      onPressed: () => _scanFoodImage(),
                    ),
                  ],
                ),
              ),
            ],

            if (_isAnalyzing) ...[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Menganalisis piring makanan dengan AI Vision...',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Mendeteksi objek, estimasi volume, dan mencocokkan ke database gizi',
                        style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),
            ],

            if (_visionResponse != null && !_visionResponse!.isFood) ...[
              // Non-food fallback state
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.no_meals_rounded, size: 60, color: AppColors.warning),
                      const SizedBox(height: 16),
                      const Text(
                        'Foto Tidak Terdeteksi Sebagai Makanan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _visionResponse!.nonFoodReason ?? 'AI tidak menemukan objek makanan pada foto yang diunggah.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Coba Foto Lain'),
                        onPressed: () => _scanFoodImage(),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('Gunakan Input Teks Saja'),
                        onPressed: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => TextFoodEntryDialog(
                              mealType: widget.mealType,
                              mealTitle: widget.mealTitle,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (_visionResponse != null && _visionResponse!.isFood) ...[
              // Food draft items detected
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Estimasi AI: Nilai gizi berasal dari foto. Periksa dan sesuaikan porsi sebelum menyimpan.',
                        style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _visionResponse!.draftItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _visionResponse!.draftItems[index];
                    final currentScale = _portionScales[index] ?? 1.0;
                    final scaledCalories = (item.calories * currentScale).round();
                    final scaledGrams = (item.estimatedGrams * currentScale).round();

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
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      item.foodName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${(item.confidenceScore * 100).round()}% yakin',
                                        style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$scaledCalories kkal',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.calories, fontSize: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Porsi: ${item.portionDescription} (~$scaledGrams g)',
                            style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Ubah porsi: ', style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
                              for (final p in [0.5, 1.0, 1.5, 2.0])
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: ChoiceChip(
                                    label: Text('${p}x', style: const TextStyle(fontSize: 11)),
                                    selected: currentScale == p,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _portionScales[index] = p;
                                        });
                                      }
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveAllDraftItems,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text('Simpan ${_visionResponse!.draftItems.length} Makanan ke ${widget.mealTitle}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
