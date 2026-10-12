import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/workout_repository.dart';

class AiWorkoutGeneratorModal extends ConsumerStatefulWidget {
  const AiWorkoutGeneratorModal({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiWorkoutGeneratorModal(),
    );
  }

  @override
  ConsumerState<AiWorkoutGeneratorModal> createState() => _AiWorkoutGeneratorModalState();
}

class _AiWorkoutGeneratorModalState extends ConsumerState<AiWorkoutGeneratorModal> {
  String _selectedGoal = 'hypertrophy';
  int _selectedDays = 3;
  String _selectedEquipment = 'gym';

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _generatedPlan;

  final Map<String, String> _goalLabels = {
    'hypertrophy': 'Bina Otot (Hypertrophy)',
    'strength': 'Kekuatan Maksimal (Strength)',
    'endurance': 'Ketahanan & Fat Loss',
  };

  final Map<String, String> _equipmentLabels = {
    'gym': 'Peralatan Gym Lengkap',
    'dumbbell': 'Hanya Dumbbell & Matras',
    'bodyweight': 'Beban Tubuh (Calisthenics)',
  };

  Future<void> _handleGenerate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(workoutRepositoryProvider);
      final result = await repo.generateAIWorkout(
        goal: _selectedGoal,
        daysPerWeek: _selectedDays,
        equipment: _selectedEquipment,
      );

      if (mounted) {
        setState(() {
          _generatedPlan = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal merancang program latihan AI: ${e.toString()}';
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
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
                    child: Icon(Icons.auto_awesome, color: theme.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Workout Coach',
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
          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              child: _generatedPlan == null
                  ? _buildGeneratorForm(theme)
                  : _buildGeneratedResult(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratorForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rancang program latihan terstruktur otomatis yang disesuaikan dengan target, jadwal mingguan, dan alat yang tersedia.',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
        ),
        const SizedBox(height: 20),

        // Target / Sasaran
        Text(
          'Target Utama Latihan',
          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._goalLabels.entries.map((entry) {
          final isSelected = _selectedGoal == entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _selectedGoal = entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primaryColor.withAlpha(40) : Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? theme.primaryColor : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? theme.primaryColor : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),

        // Frekuensi Hari per Minggu
        Text(
          'Frekuensi Latihan per Minggu',
          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [2, 3, 4, 5].map((days) {
              final isSelected = _selectedDays == days;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$days Hari / Minggu'),
                  selected: isSelected,
                  selectedColor: theme.primaryColor.withAlpha(60),
                  onSelected: (val) {
                    if (val) setState(() => _selectedDays = days);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Ketersediaan Alat
        Text(
          'Peralatan Tersedia',
          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._equipmentLabels.entries.map((entry) {
          final isSelected = _selectedEquipment == entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _selectedEquipment = entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primaryColor.withAlpha(40) : Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? theme.primaryColor : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.fitness_center : Icons.fitness_center_outlined,
                      color: isSelected ? theme.primaryColor : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

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
          key: const Key('generate_ai_workout_btn'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _isLoading ? null : _handleGenerate,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt, size: 20),
                    SizedBox(width: 8),
                    Text('Rancang Rutinitas Latihan AI', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildGeneratedResult(ThemeData theme) {
    final title = _generatedPlan?['title'] ?? 'Rutinitas Latihan AI';
    final desc = _generatedPlan?['description'] ?? '';
    final rawExercises = _generatedPlan?['exercises'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.primaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.primaryColor.withAlpha(80)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: theme.primaryColor, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[300]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Daftar Latihan (${rawExercises.length} Gerakan):',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        ...rawExercises.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final ex = entry.value as Map<String, dynamic>;
          final name = ex['name'] ?? 'Latihan';
          final muscle = ex['targetMuscle'] ?? ex['target_muscle'] ?? '';
          final sets = ex['targetSets'] ?? ex['target_sets'] ?? 3;
          final reps = ex['targetReps'] ?? ex['target_reps'] ?? 10;
          final rest = ex['restSeconds'] ?? ex['rest_seconds'] ?? 90;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.primaryColor.withAlpha(40),
                foregroundColor: theme.primaryColor,
                child: Text('$idx', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                'Target: $muscle • $sets Set × $reps Reps • Istirahat $rest dtk',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        }),

        const SizedBox(height: 20),
        ElevatedButton(
          key: const Key('save_ai_workout_btn'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Program latihan berhasil disimpan ke Rutinitas!')),
            );
            if (Navigator.canPop(context)) Navigator.pop(context, true);
          },
          child: const Text('Simpan & Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
