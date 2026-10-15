import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/workout_repository.dart';
import '../domain/workout_models.dart';

class ActiveWorkoutSessionSheet extends ConsumerStatefulWidget {
  final WorkoutSessionItem session;
  final List<ExerciseItem> exercises;

  const ActiveWorkoutSessionSheet({
    super.key,
    required this.session,
    required this.exercises,
  });

  static Future<bool?> show(
    BuildContext context, {
    String title = 'Sesi Latihan',
    String? routineId,
  }) async {
    final repo = ProviderScope.containerOf(context).read(workoutRepositoryProvider);
    final session = await repo.startSession(title: title, routineId: routineId);
    final exercises = await repo.getExercises();
    if (!context.mounted) return null;
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ActiveWorkoutSessionSheet(
        session: session,
        exercises: exercises.isNotEmpty
            ? exercises
            : [
                ExerciseItem(
                  id: 'default-ex',
                  name: 'Latihan Umum',
                  targetMuscle: 'Full Body',
                  category: 'barbell',
                  equipment: 'Barbell',
                ),
              ],
      ),
    );
  }

  @override
  ConsumerState<ActiveWorkoutSessionSheet> createState() => _ActiveWorkoutSessionSheetState();
}

class _ActiveWorkoutSessionSheetState extends ConsumerState<ActiveWorkoutSessionSheet> {
  late WorkoutSessionItem _currentSession;
  late ExerciseItem _selectedExercise;
  final _repsController = TextEditingController(text: '10');
  final _weightController = TextEditingController(text: '60');
  final _notesController = TextEditingController();

  final List<WorkoutSetItem> _loggedSets = [];
  double _runningVolumeKg = 0;
  bool _isSavingSet = false;
  bool _isFinishing = false;
  String? _lastPRNotice;

  Timer? _restTimer;
  int _restSecondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    _selectedExercise = widget.exercises.isNotEmpty
        ? widget.exercises.first
        : ExerciseItem(id: 'dummy', name: 'Barbell Bench Press', targetMuscle: 'Chest', category: 'barbell', equipment: 'Barbell');
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() => _restSecondsRemaining = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining <= 1) {
        timer.cancel();
        if (mounted) setState(() => _restSecondsRemaining = 0);
      } else {
        if (mounted) setState(() => _restSecondsRemaining--);
      }
    });
  }

  Future<void> _recordSet() async {
    final reps = int.tryParse(_repsController.text) ?? 10;
    final weight = double.tryParse(_weightController.text) ?? 0;
    final setNumber = _loggedSets.where((s) => s.exerciseId == _selectedExercise.id).length + 1;

    setState(() {
      _isSavingSet = true;
      _lastPRNotice = null;
    });

    try {
      final repo = ref.read(workoutRepositoryProvider);
      final result = await repo.logSet(
        sessionId: _currentSession.id,
        exerciseId: _selectedExercise.id,
        setNumber: setNumber,
        reps: reps,
        weightKg: weight,
      );

      final isPR = result['isPersonalRecord'] as bool? ?? false;
      final set = WorkoutSetItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        exerciseId: _selectedExercise.id,
        exerciseName: _selectedExercise.name,
        setNumber: setNumber,
        reps: reps,
        weightKg: weight,
        isPR: isPR,
      );

      if (mounted) {
        setState(() {
          _loggedSets.add(set);
          _runningVolumeKg += (reps * weight);
          if (isPR) {
            _lastPRNotice = '🎉 Rekor Pribadi (PR) Baru Terdeteksi!';
          }
        });
        _startRestTimer(90);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: AppColors.error, content: Text('Gagal mencatat set.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingSet = false);
    }
  }

  Future<void> _finishSession() async {
    setState(() => _isFinishing = true);
    try {
      final repo = ref.read(workoutRepositoryProvider);
      final finished = await repo.finishSession(
        sessionId: _currentSession.id,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('Sesi ${_currentSession.title} selesai! Total volume: ${finished.totalVolumeKg.round()} kg.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: AppColors.error, content: Text('Gagal menyelesaikan sesi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkBackground,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Session info & close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          const Text('SESI AKTIF', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(_currentSession.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Volume and Rest Timer Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Total Volume', style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
                      Text('${_runningVolumeKg.round()} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.carbs)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Total Set', style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
                      Text('${_loggedSets.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Rest Timer', style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
                      Text(
                        _restSecondsRemaining > 0 ? '${_restSecondsRemaining}s' : 'Siap',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _restSecondsRemaining > 0 ? AppColors.warning : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_lastPRNotice != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Text(_lastPRNotice!, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],

            const SizedBox(height: 12),

            // Exercise Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedExercise.id,
              decoration: InputDecoration(
                labelText: 'Pilih Latihan',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: widget.exercises.map((ex) {
                return DropdownMenuItem(value: ex.id, child: Text(ex.name));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  final found = widget.exercises.firstWhere((e) => e.id == val, orElse: () => _selectedExercise);
                  setState(() => _selectedExercise = found);
                }
              },
            ),

            const SizedBox(height: 12),

            // Inputs: Weight and Reps
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Beban (kg)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Repetisi',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  key: const Key('log_set_btn'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(90, 48)),
                  onPressed: _isSavingSet ? null : _recordSet,
                  child: _isSavingSet
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('+ Set'),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text('Riwayat Set Sesi Ini:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),

            // Logged sets list
            Expanded(
              child: _loggedSets.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada set yang dicatat.\nMasukkan beban & rep lalu tekan tombol + Set.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _loggedSets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final set = _loggedSets[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.darkSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: set.isPR ? AppColors.primary : AppColors.darkBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(set.exerciseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('Set #${set.setNumber} • ${set.weightKg.round()} kg × ${set.reps} reps', style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
                                ],
                              ),
                              if (set.isPR)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('PR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                                )
                              else
                                Text('${(set.weightKg * set.reps).round()} kg vol', style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 12),
            ElevatedButton.icon(
              key: const Key('finish_workout_btn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
              ),
              icon: _isFinishing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.check_circle_rounded, color: Colors.black),
              label: const Text('Selesaikan Sesi Latihan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              onPressed: _isFinishing ? null : _finishSession,
            ),
          ],
        ),
      ),
    );
  }
}
