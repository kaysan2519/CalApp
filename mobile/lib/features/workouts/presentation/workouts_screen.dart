import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/workout_repository.dart';
import '../domain/workout_models.dart';
import 'active_workout_session_sheet.dart';
import 'ai_workout_generator_modal.dart';
import 'body_measurement_modal.dart';
import 'exercise_detail_modal.dart';

class WorkoutsScreen extends ConsumerStatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  ConsumerState<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends ConsumerState<WorkoutsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & filter state untuk katalog latihan
  String _searchQuery = '';
  String _selectedMuscle = 'Semua';

  // Otot filter
  final List<String> _muscleFilters = [
    'Semua',
    'Chest',
    'Back',
    'Quads',
    'Hamstrings',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Abs',
    'Calves',
  ];

  // Refresh triggers
  int _refreshCounter = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _triggerRefresh() {
    if (mounted) {
      setState(() => _refreshCounter++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym & Latihan', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: _triggerRefresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: theme.primaryColor,
          indicatorWeight: 3,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.fitness_center), text: 'Sesi & Rutin'),
            Tab(icon: Icon(Icons.menu_book), text: 'Katalog Latihan'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Rekor PR'),
            Tab(icon: Icon(Icons.monitor_weight), text: 'Progres Tubuh'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSessionsTab(theme),
          _buildExercisesTab(theme),
          _buildPersonalRecordsTab(theme),
          _buildBodyProgressTab(theme),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 1: Sesi & Rutinitas
  // ----------------------------------------------------
  Widget _buildSessionsTab(ThemeData theme) {
    final repo = ref.watch(workoutRepositoryProvider);

    return FutureBuilder<List<dynamic>>(
      key: ValueKey('sessions_future_$_refreshCounter'),
      future: Future.wait([
        repo.getRoutines(),
        repo.getUserSessions(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Text('Memuat data latihan...'));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                  const SizedBox(height: 8),
                  Text('Gagal memuat: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _triggerRefresh,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        final routines = (snapshot.data?[0] as List<WorkoutRoutineItem>?) ?? [];
        final sessions = (snapshot.data?[1] as List<WorkoutSessionItem>?) ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quick Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    key: const Key('start_workout_session_btn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Mulai Latihan', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final updated = await ActiveWorkoutSessionSheet.show(
                        context,
                        title: 'Sesi Latihan Mandiri',
                      );
                      if (updated == true) _triggerRefresh();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('open_ai_workout_btn'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: theme.primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(Icons.auto_awesome, color: theme.primaryColor),
                    label: Text(
                      'AI Rutinitas',
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor),
                    ),
                    onPressed: () async {
                      final generated = await AiWorkoutGeneratorModal.show(context);
                      if (generated == true) _triggerRefresh();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section: Rutinitas Saya
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rutinitas Latihan (${routines.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (routines.isEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Belum ada rutinitas latihan. Gunakan tombol "AI Rutinitas" di atas untuk membuat rancangan latihan otomatis!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...routines.map((routine) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                routine.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            Chip(
                              label: Text(
                                '${routine.daysPerWeek}x / minggu',
                                style: const TextStyle(fontSize: 11),
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        if (routine.description != null && routine.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            routine.description!,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: routine.exercises.map((ex) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${ex.name} (${ex.targetSets}x${ex.targetReps})',
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor.withAlpha(40),
                              foregroundColor: theme.primaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.play_circle_outline, size: 18),
                            label: const Text('Mulai Rutinitas Ini'),
                            onPressed: () async {
                              final updated = await ActiveWorkoutSessionSheet.show(
                                context,
                                routineId: routine.id,
                                title: routine.title,
                              );
                              if (updated == true) _triggerRefresh();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),

            // Section: Riwayat Sesi Terakhir
            Text(
              'Riwayat Sesi Terakhir (${sessions.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (sessions.isEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Belum ada sesi latihan yang selesai. Mulai latihan pertama Anda hari ini!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...sessions.map((sess) {
                final durationMins = (sess.durationSeconds / 60).round();
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withAlpha(30),
                      foregroundColor: Colors.orange,
                      child: const Icon(Icons.check_circle_outline),
                    ),
                    title: Text(sess.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '$durationMins Menit • ${sess.sets.length} Set • Total Volume: ${sess.totalVolumeKg.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      sess.startedAt.split('T').first,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------
  // TAB 2: Katalog Latihan
  // ----------------------------------------------------
  Widget _buildExercisesTab(ThemeData theme) {
    final repo = ref.watch(workoutRepositoryProvider);
    final muscleParam = _selectedMuscle == 'Semua' ? null : _selectedMuscle;

    return FutureBuilder<List<ExerciseItem>>(
      key: ValueKey('exercises_tab_${_selectedMuscle}_${_searchQuery}_$_refreshCounter'),
      future: repo.getExercises(
        query: _searchQuery.isEmpty ? null : _searchQuery,
        muscle: muscleParam,
      ),
      builder: (context, snapshot) {
        return Column(
          children: [
            // Search Input & Filter Chips
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                children: [
                  TextField(
                    key: const Key('exercise_search_input'),
                    decoration: InputDecoration(
                      hintText: 'Cari nama gerakan latihan...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim());
                    },
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _muscleFilters.map((muscle) {
                        final isSelected = _selectedMuscle == muscle;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(muscle),
                            selected: isSelected,
                            selectedColor: theme.primaryColor.withAlpha(50),
                            onSelected: (val) {
                              if (val) setState(() => _selectedMuscle = muscle);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Result List
            Expanded(
              child: Builder(
                builder: (_) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Text('Memuat katalog latihan...'));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Gagal memuat: ${snapshot.error}'));
                  }

                  final exercises = snapshot.data ?? [];
                  if (exercises.isEmpty) {
                    return const Center(
                      child: Text(
                        'Tidak ada latihan yang cocok dengan kriteria pencarian.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final ex = exercises[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ExpansionTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              ExerciseDetailModal.getExerciseImageUrl(ex.name, ex.targetMuscle, ex.category),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => CircleAvatar(
                                backgroundColor: theme.primaryColor.withAlpha(30),
                                foregroundColor: theme.primaryColor,
                                child: const Icon(Icons.fitness_center, size: 20),
                              ),
                            ),
                          ),
                          title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'Target: ${ex.targetMuscle} • Alat: ${ex.equipment}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  const Text('Petunjuk Eksekusi:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    ex.instructions ?? 'Jaga postur punggung tetap lurus dan kendalikan tempo gerakan.',
                                    style: TextStyle(color: Colors.grey[400], height: 1.3),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF6366F1).withAlpha(40),
                                        foregroundColor: const Color(0xFF818CF8),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.visibility_rounded, size: 16),
                                      label: const Text('Buka Foto & Panduan Gerakan Lengkap'),
                                      onPressed: () => ExerciseDetailModal.show(context, exercise: ex),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------
  // TAB 3: Rekor Pribadi (PR)
  // ----------------------------------------------------
  Widget _buildPersonalRecordsTab(ThemeData theme) {
    final repo = ref.watch(workoutRepositoryProvider);

    return FutureBuilder<List<PersonalRecordItem>>(
      key: ValueKey('pr_future_$_refreshCounter'),
      future: repo.getPersonalRecords(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Text('Memuat Rekor Pribadi...'));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat rekor: ${snapshot.error}'));
        }

        final prs = snapshot.data ?? [];

        if (prs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum Ada Rekor Pribadi (PR)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Saat Anda mencatat angkatan baru di sesi latihan, Cal akan otomatis mendeteksi rekor beban tertinggi dan menghitung estimasi 1 Rep Max (1RM) Anda!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: prs.length,
          itemBuilder: (context, index) {
            final pr = prs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pr.exerciseName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Beban Tertinggi: ${pr.maxWeightKg} kg × ${pr.maxReps} Reps',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Estimasi 1RM: ${pr.estimated1RM} kg',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (pr.achievedAt.isNotEmpty)
                      Text(
                        pr.achievedAt.split('T').first,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------
  // TAB 4: Progres Tubuh (F12)
  // ----------------------------------------------------
  Widget _buildBodyProgressTab(ThemeData theme) {
    final repo = ref.watch(workoutRepositoryProvider);

    return FutureBuilder<BodyProgressSummary>(
      key: ValueKey('body_progress_future_$_refreshCounter'),
      future: repo.getBodyMeasurements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Text('Memuat progres tubuh...'));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat: ${snapshot.error}'));
        }

        final summary = snapshot.data;
        final history = summary?.history ?? [];
        final latestWeight = summary?.latestWeight;
        final weightDelta = summary?.weightDelta ?? 0.0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Top Weight Card Summary
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.withAlpha(40),
                    theme.primaryColor.withAlpha(10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.primaryColor.withAlpha(60)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Berat Badan Terkini', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        latestWeight != null ? '$latestWeight kg' : '-- kg',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Perubahan (Delta)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            weightDelta < 0
                                ? Icons.arrow_downward
                                : (weightDelta > 0 ? Icons.arrow_upward : Icons.remove),
                            size: 16,
                            color: weightDelta <= 0 ? Colors.greenAccent : Colors.orangeAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${weightDelta >= 0 ? "+" : ""}${weightDelta.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: weightDelta <= 0 ? Colors.greenAccent : Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Catat Pengukuran Baru
            ElevatedButton.icon(
              key: const Key('open_body_measurement_btn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Catat Ukuran Tubuh Baru', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                final saved = await BodyMeasurementModal.show(context);
                if (saved == true) _triggerRefresh();
              },
            ),
            const SizedBox(height: 24),

            // Section Riwayat Pengukuran
            Text(
              'Riwayat Pengukuran (${history.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (history.isEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Belum ada riwayat ukuran tubuh. Tekan tombol di atas untuk mencatat berat badan dan lingkar tubuh!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...history.map((m) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${m.weightKg} kg',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              m.measuredDate.split('T').first,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        if (m.waistCm != null || m.chestCm != null || m.hipsCm != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Lingkar: '
                            '${m.waistCm != null ? "Pinggang: ${m.waistCm}cm  " : ""}'
                            '${m.chestCm != null ? "Dada: ${m.chestCm}cm  " : ""}'
                            '${m.hipsCm != null ? "Pinggul: ${m.hipsCm}cm" : ""}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                        if (m.notes != null && m.notes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '"${m.notes}"',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
