import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/workout_repository.dart';
import '../domain/workout_models.dart';

class ExerciseDetailModal extends ConsumerStatefulWidget {
  final ExerciseItem exercise;

  const ExerciseDetailModal({
    super.key,
    required this.exercise,
  });

  static Future<bool?> show(BuildContext context, {required ExerciseItem exercise}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExerciseDetailModal(exercise: exercise),
    );
  }

  static String getExerciseImageUrl(String name, String targetMuscle, String category) {
    final lower = name.toLowerCase();
    if (lower.contains('bench press')) {
      return 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=600&q=80';
    } else if (lower.contains('squat') || lower.contains('lunges')) {
      return 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&w=600&q=80';
    } else if (lower.contains('deadlift')) {
      return 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=600&q=80';
    } else if (lower.contains('leg press') || lower.contains('extension') || lower.contains('curl')) {
      return 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?auto=format&fit=crop&w=600&q=80';
    } else if (lower.contains('pull-up') || lower.contains('pulldown') || lower.contains('row')) {
      return 'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?auto=format&fit=crop&w=600&q=80';
    } else if (lower.contains('push-up') || lower.contains('dip') || category == 'bodyweight') {
      return 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=600&q=80';
    } else if (lower.contains('shoulder') || lower.contains('overhead') || lower.contains('lateral')) {
      return 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?auto=format&fit=crop&w=600&q=80';
    } else if (lower.contains('cable') || lower.contains('fly')) {
      return 'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?auto=format&fit=crop&w=600&q=80';
    } else if (lower.contains('plank') || targetMuscle.toLowerCase().contains('abs')) {
      return 'https://images.unsplash.com/photo-1566241142559-40e1dab266c6?auto=format&fit=crop&w=600&q=80';
    }
    return 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=600&q=80';
  }

  @override
  ConsumerState<ExerciseDetailModal> createState() => _ExerciseDetailModalState();
}

class _ExerciseDetailModalState extends ConsumerState<ExerciseDetailModal> {
  final List<TextEditingController> _weightControllers = [
    TextEditingController(text: '60'),
    TextEditingController(text: '60'),
    TextEditingController(text: '65'),
  ];
  final List<TextEditingController> _repsControllers = [
    TextEditingController(text: '10'),
    TextEditingController(text: '10'),
    TextEditingController(text: '8'),
  ];
  bool _isSaving = false;

  @override
  void dispose() {
    for (final c in _weightControllers) {
      c.dispose();
    }
    for (final c in _repsControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _getDetailedSteps(String name, String? instructions) {
    if (instructions != null && instructions.contains('.')) {
      final split = instructions.split('.').where((s) => s.trim().isNotEmpty).toList();
      if (split.length >= 2) return split.map((s) => s.trim()).toList();
    }

    final lower = name.toLowerCase();
    if (lower.contains('bench press')) {
      return [
        'Setup: Berbaring di flat bench. Mata tepat di bawah bar. Tarik belikat (scapula retraction) dan kunci telapak kaki rata ke lantai.',
        'Grip: Genggam bar sedikit lebih lebar dari bahu, kunci ibu jari melingkari bar (full thumb grip).',
        'Penurunan: Turunkan bar ke tengah dada bawah dengan siku membentuk sudut 45-70° dari rusuk selama 2 detik terkontrol.',
        'Dorongan: Dorong bar eksplosif lurus ke atas sambil membuang napas kuat tanpa mengangkat bokong dari bangku.',
      ];
    } else if (lower.contains('squat')) {
      return [
        'Setup: Tempatkan bar di atas bantalan otot trapezius. Tarik siku ke belakang untuk mengunci shelf otot.',
        'Stance: Berdiri selebar bahu, putar ujung jari kaki 15-30° ke luar.',
        'Jongkok: Tarik napas ke diafragma, kunci perut (bracing), turunkan pinggul ke belakang dan ke bawah hingga paha sejajar lantai.',
        'Bangkit: Dorong lantai melalui tumit, dorong pinggul ke depan hingga tegak kembali, lalu buang napas.',
      ];
    } else if (lower.contains('deadlift')) {
      return [
        'Setup: Berdiri kaki selebar pinggul, bar menyentuh tulang kering. Genggam bar tepat di luar garis lutut.',
        'Wedge: Turunkan pinggul, busungkan dada, kencangkan punggung agar tulang belakang dalam posisi lurus netral.',
        'Tarikan: Dorong lantai menjauh dengan kaki seolah melakukan leg press, jaga bar selalu menempel menyusuri kaki.',
        'Lockout: Setelah bar melewati lutut, dorong pinggul ke depan hingga tegak lurus sempurna tanpa melempar punggung ke belakang.',
      ];
    } else if (lower.contains('leg press')) {
      return [
        'Setup: Duduk di sandaran mesin, pastikan pinggang dan punggung menempel rapat di bantalan tanpa ada celah.',
        'Penempatan Kaki: Tempatkan telapak kaki di tengah sled platform selebar bahu, jari kaki sedikit menyerong keluar.',
        'Penurunan: Buka tuas pengaman, turunkan pelat beban perlahan hingga lutut membentuk sudut 90 derajat.',
        'Dorongan: Dorong pelat beban menjauh melalui tumit dan telapak kaki tengah hingga kaki hampir lurus.',
      ];
    }

    return [
      'Setup: Posisikan tubuh pada posisi awal yang stabil dan sesuaikan beban pada tingkat yang terkontrol.',
      'Aktivasi Otot: Tarik napas dalam, kencangkan otot inti (core), dan posisikan sendi pada sudut aman.',
      'Fase Kontraksi: Eksekusi gerakan dengan tempo terkontrol, kontraksikan otot target selama 1 detik di puncak gerakan.',
      'Fase Pelepasan: Kembalikan beban secara perlahan ke posisi awal dalam waktu 2-3 detik sambil menjaga ketegangan otot.',
    ];
  }

  String _getFormTips(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('bench press')) {
      return 'Hindari melebarkan siku 90 derajat sejajar bahu agar sendi rotator cuff tidak terjepit. Jangan memantulkan bar di tulang dada.';
    } else if (lower.contains('squat')) {
      return 'Jaga lutut selalu bergerak searah dengan jari kaki, jangan biarkan lutut roboh ke dalam (knee valgus). Tumit tidak boleh terangkat.';
    } else if (lower.contains('deadlift')) {
      return 'Jangan pernah mengangkat dengan punggung melengkung untuk menghindari cedera berbahaya pada diskus tulang belakang.';
    } else if (lower.contains('leg press')) {
      return 'PERINGATAN KRUSIAL: Jangan pernah mengunci lutut (hyperextension) di puncak dorongan karena berisiko cedera tempurung lutut parah!';
    } else if (lower.contains('push-up') || lower.contains('dip')) {
      return 'Pertahankan tubuh lurus dari kepala hingga tumit. Jangan biarkan pinggul merosot ke bawah.';
    }
    return 'Pertahankan postur tulang belakang netral, hindari menggunakan momentum tubuh berlebih, dan bernapaslah secara teratur.';
  }

  Future<void> _logExerciseSets() async {
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(workoutRepositoryProvider);
      final session = await repo.startSession(
        title: 'Latihan: ${widget.exercise.name}',
      );

      for (var i = 0; i < _weightControllers.length; i++) {
        final weight = double.tryParse(_weightControllers[i].text) ?? 50.0;
        final reps = int.tryParse(_repsControllers[i].text) ?? 10;
        await repo.logSet(
          sessionId: session.id,
          exerciseId: widget.exercise.id,
          setNumber: i + 1,
          reps: reps,
          weightKg: weight,
        );
      }

      await repo.finishSession(sessionId: session.id, notes: 'Dicatat dari katalog latihan');

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('${widget.exercise.name} berhasil dicatat ke sesi latihan!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Gagal menyimpan sesi latihan: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final imageUrl = ExerciseDetailModal.getExerciseImageUrl(ex.name, ex.targetMuscle, ex.category);
    final steps = _getDetailedSteps(ex.name, ex.instructions);
    final tips = _getFormTips(ex.name);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.96,
      minChildSize: 0.5,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0B0E14),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),

              // Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white70),
                      label: const Text('Kembali', style: TextStyle(color: Colors.white70)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF818CF8).withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF818CF8).withAlpha(80)),
                      ),
                      child: Text(
                        ex.equipment,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF818CF8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    // Visual Photo Hero Banner
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Image.network(
                            imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              color: const Color(0xFF141923),
                              child: const Icon(Icons.fitness_center_rounded, size: 64, color: Colors.white24),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Color(0xCC0B0E14)],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 14,
                            right: 14,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ex.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Kategori: ${ex.category.toUpperCase()} • Target: ${ex.targetMuscle}',
                                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Target Muscle Cards
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141923),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withAlpha(15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.track_changes_rounded, color: Color(0xFF34D399), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Target Otot Utama',
                                  style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  ex.targetMuscle,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Presisi Form',
                              style: TextStyle(fontSize: 10, color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Step-by-Step Instructions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141923),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.directions_run_rounded, color: Color(0xFF10B981), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Arahan Langkah Demi Langkah:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...steps.asMap().entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: const Color(0xFF818CF8).withAlpha(50),
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF818CF8)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.35),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Safety & Form Tips
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.withAlpha(60)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Tips Form Aman & Hindari Cedera:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tips,
                            style: const TextStyle(fontSize: 11, color: Colors.amberAccent, height: 1.35),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Set & Reps Quick Logger
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141923),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Catat Set & Repetisi Sesi Ini:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(3, (idx) {
                              return Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(right: idx < 2 ? 8 : 0),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Set ${idx + 1}',
                                        style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: _weightControllers[idx],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                        decoration: const InputDecoration(
                                          suffixText: 'kg',
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                        ),
                                      ),
                                      TextField(
                                        controller: _repsControllers[idx],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Color(0xFF818CF8), fontSize: 11),
                                        decoration: const InputDecoration(
                                          suffixText: 'reps',
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _isSaving ? null : _logExerciseSets,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: Text(
                                _isSaving ? 'Menyimpan Sesi...' : 'Simpan Gerakan ke Sesi Latihan',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
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
  }
}
