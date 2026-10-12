import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/workout_repository.dart';

class BodyMeasurementModal extends ConsumerStatefulWidget {
  const BodyMeasurementModal({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BodyMeasurementModal(),
    );
  }

  @override
  ConsumerState<BodyMeasurementModal> createState() => _BodyMeasurementModalState();
}

class _BodyMeasurementModalState extends ConsumerState<BodyMeasurementModal> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _waistController = TextEditingController();
  final _chestController = TextEditingController();
  final _hipsController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _weightController.dispose();
    _waistController.dispose();
    _chestController.dispose();
    _hipsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      setState(() => _errorMessage = 'Berat badan harus berupa angka valid');
      return;
    }

    final waist = double.tryParse(_waistController.text.trim());
    final chest = double.tryParse(_chestController.text.trim());
    final hips = double.tryParse(_hipsController.text.trim());
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(workoutRepositoryProvider);
      await repo.logBodyMeasurement(
        weightKg: weight,
        waistCm: waist,
        chestCm: chest,
        hipsCm: hips,
        notes: notes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ukuran tubuh berhasil dicatat!')),
        );
        if (Navigator.canPop(context)) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal menyimpan ukuran: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 24,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.monitor_weight_outlined, color: theme.primaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Catat Ukuran Tubuh',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Berat Badan (Wajib)
                    TextFormField(
                      key: const Key('body_weight_input'),
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Berat Badan (kg) *',
                        hintText: 'Contoh: 70.5',
                        prefixIcon: const Icon(Icons.scale),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Berat badan wajib diisi';
                        }
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null || parsed <= 20 || parsed >= 300) {
                          return 'Masukkan berat badan yang realistis (20-300 kg)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Lingkar Pinggang
                    TextFormField(
                      key: const Key('body_waist_input'),
                      controller: _waistController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Lingkar Pinggang (cm) [Opsional]',
                        hintText: 'Contoh: 82.0',
                        prefixIcon: const Icon(Icons.straighten),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lingkar Dada
                    TextFormField(
                      key: const Key('body_chest_input'),
                      controller: _chestController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Lingkar Dada (cm) [Opsional]',
                        hintText: 'Contoh: 98.0',
                        prefixIcon: const Icon(Icons.fitness_center),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lingkar Pinggul
                    TextFormField(
                      key: const Key('body_hips_input'),
                      controller: _hipsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Lingkar Pinggul (cm) [Opsional]',
                        hintText: 'Contoh: 95.0',
                        prefixIcon: const Icon(Icons.accessibility_new),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Catatan
                    TextFormField(
                      key: const Key('body_notes_input'),
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Catatan Tambahan [Opsional]',
                        hintText: 'Misal: Ditimbang pagi hari sebelum makan',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                      ),
                    ],

                    const SizedBox(height: 24),
                    ElevatedButton(
                      key: const Key('save_body_measurement_btn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isLoading ? null : _handleSave,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Simpan Pengukuran', style: TextStyle(fontWeight: FontWeight.bold)),
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
