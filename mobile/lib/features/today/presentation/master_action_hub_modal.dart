import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../nutrition/data/ai_repository.dart';
import '../../nutrition/domain/ai_food_models.dart';
import '../../nutrition/presentation/ai_vision_food_sheet.dart';
import '../../nutrition/presentation/nutrition_state_notifier.dart';
import '../../workouts/data/workout_repository.dart';
import '../../workouts/domain/workout_models.dart';
import '../../workouts/presentation/active_workout_session_sheet.dart';
import '../../workouts/presentation/ai_workout_generator_modal.dart';
import '../../workouts/presentation/exercise_detail_modal.dart';

class MasterActionHubModal extends ConsumerStatefulWidget {
  const MasterActionHubModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MasterActionHubModal(),
    );
  }

  @override
  ConsumerState<MasterActionHubModal> createState() => _MasterActionHubModalState();
}

class _MasterActionHubModalState extends ConsumerState<MasterActionHubModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Food Hub State ---
  String _selectedMealType = 'lunch';
  String _selectedMealTitle = 'Makan Siang';
  final TextEditingController _foodTextController = TextEditingController();
  final TextEditingController _coEditorController = TextEditingController();
  bool _isFoodAnalyzing = false;
  bool _isFoodSaving = false;
  String? _foodError;
  List<AiVisionDraftItem> _draftFoodItems = [];
  final Map<int, double> _portionScales = {};

  // --- Workout Hub State ---
  int _selectedDurationMinutes = 30;
  String _selectedEquipmentCategory = 'gym';
  final TextEditingController _workoutFreeformController = TextEditingController();
  final TextEditingController _exerciseSearchController = TextEditingController();
  String _selectedMuscleFilter = 'Semua';
  List<ExerciseItem> _allExercises = [];
  bool _isLoadingExercises = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Auto select meal slot based on current hour
    final hour = DateTime.now().hour;
    if (hour < 11) {
      _selectedMealType = 'breakfast';
      _selectedMealTitle = 'Sarapan';
    } else if (hour < 16) {
      _selectedMealType = 'lunch';
      _selectedMealTitle = 'Makan Siang';
    } else if (hour < 20) {
      _selectedMealType = 'dinner';
      _selectedMealTitle = 'Makan Malam';
    } else {
      _selectedMealType = 'snack';
      _selectedMealTitle = 'Camilan';
    }

    _loadExercises();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _foodTextController.dispose();
    _coEditorController.dispose();
    _workoutFreeformController.dispose();
    _exerciseSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      final repo = ref.read(workoutRepositoryProvider);
      final list = await repo.getExercises();
      if (mounted) {
        setState(() {
          _allExercises = list;
          _isLoadingExercises = false;
        });
      }
    } catch (_) {
      // Fallback seed exercises
      if (mounted) {
        setState(() {
          _allExercises = [
            ExerciseItem(
              id: 'ex-bench-press',
              name: 'Barbell Bench Press',
              targetMuscle: 'Chest',
              category: 'barbell',
              equipment: 'Barbell & Flat Bench',
              instructions: 'Posisikan mata di bawah bar, turunkan bar ke tengah dada dengan kontrol.',
            ),
            ExerciseItem(
              id: 'ex-incline-press',
              name: 'Incline Dumbbell Press',
              targetMuscle: 'Chest',
              category: 'dumbbell',
              equipment: 'Dumbbells & Incline Bench',
              instructions: 'Sudut bangku 30 derajat, dorong vertikal dengan siku stabil.',
            ),
            ExerciseItem(
              id: 'ex-push-up',
              name: 'Push-Up',
              targetMuscle: 'Chest',
              category: 'bodyweight',
              equipment: 'Beban Badan',
              instructions: 'Tubuh lurus seperti papan, dada menyentuh lantai lalu dorong kuat.',
            ),
            ExerciseItem(
              id: 'ex-squat',
              name: 'Barbell Back Squat',
              targetMuscle: 'Quads',
              category: 'barbell',
              equipment: 'Barbell & Rack',
              instructions: 'Turun sampai paha sejajar lantai, dorong tumit ke atas.',
            ),
            ExerciseItem(
              id: 'ex-deadlift',
              name: 'Conventional Deadlift',
              targetMuscle: 'Back',
              category: 'barbell',
              equipment: 'Barbell',
              instructions: 'Punggung netral, dorong lantai dengan kaki sambil menarik bar ke pinggul.',
            ),
            ExerciseItem(
              id: 'ex-pullup',
              name: 'Pull-Up',
              targetMuscle: 'Back',
              category: 'bodyweight',
              equipment: 'Pull-Up Bar',
              instructions: 'Tarik dada ke arah palang, tahan sejenak di puncak kontraksi.',
            ),
            ExerciseItem(
              id: 'ex-shoulder-press',
              name: 'Seated Dumbbell Shoulder Press',
              targetMuscle: 'Shoulders',
              category: 'dumbbell',
              equipment: 'Dumbbells & Bench',
              instructions: 'Dorong dumbbell lurus ke atas kepala tanpa melengkungkan pinggang.',
            ),
            ExerciseItem(
              id: 'ex-leg-press',
              name: 'Leg Press',
              targetMuscle: 'Quads',
              category: 'machine',
              equipment: 'Leg Press Machine',
              instructions: 'Kaki selebar bahu di platform, turunkan lutut 90 derajat lalu dorong.',
            ),
            ExerciseItem(
              id: 'ex-lat-pulldown',
              name: 'Lat Pulldown',
              targetMuscle: 'Back',
              category: 'machine',
              equipment: 'Lat Pulldown Machine',
              instructions: 'Tarik palang ke dada atas dengan mengaktifkan otot sayap punggung.',
            ),
          ];
          _isLoadingExercises = false;
        });
      }
    }
  }

  // --- Food Handlers ---
  Future<void> _analyzeFoodText() async {
    final text = _foodTextController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isFoodAnalyzing = true;
      _foodError = null;
    });

    try {
      final aiRepo = ref.read(aiRepositoryProvider);
      final response = await aiRepo.parseFoodText(text);

      if (mounted) {
        final List<AiVisionDraftItem> draftItems = response.parsedItems.map((item) {
          return AiVisionDraftItem(
            foodName: item.foodName,
            portionDescription: '${item.quantity} ${item.rawUnit}',
            estimatedGrams: item.normalizedGrams,
            calories: item.calories,
            proteinG: item.proteinG,
            carbsG: item.carbsG,
            fatG: item.fatG,
            confidenceScore: 0.95,
          );
        }).toList();

        setState(() {
          _draftFoodItems = draftItems;
          for (var i = 0; i < draftItems.length; i++) {
            _portionScales[i] = 1.0;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _foodError = 'Gagal memproses teks makanan. Coba masukkan nama makanan dan takarannya.';
        });
      }
    } finally {
      if (mounted) setState(() => _isFoodAnalyzing = false);
    }
  }

  Future<void> _applyCoEditorInstruction(String instruction) async {
    if (instruction.trim().isEmpty || _draftFoodItems.isEmpty) return;

    final aiRepo = ref.read(aiRepositoryProvider);
    final scaled = <AiVisionDraftItem>[];
    for (var i = 0; i < _draftFoodItems.length; i++) {
      final scale = _portionScales[i] ?? 1.0;
      scaled.add(_draftFoodItems[i].copyWith(
        estimatedGrams: (_draftFoodItems[i].estimatedGrams * scale).roundToDouble(),
        calories: (_draftFoodItems[i].calories * scale).roundToDouble(),
        proteinG: double.parse((_draftFoodItems[i].proteinG * scale).toStringAsFixed(1)),
        carbsG: double.parse((_draftFoodItems[i].carbsG * scale).toStringAsFixed(1)),
        fatG: double.parse((_draftFoodItems[i].fatG * scale).toStringAsFixed(1)),
      ));
    }

    final updated = await aiRepo.refineFoodDraft(
      items: scaled,
      instruction: instruction,
    );

    if (mounted) {
      setState(() {
        _draftFoodItems = updated;
        for (var i = 0; i < _draftFoodItems.length; i++) {
          _portionScales[i] = 1.0;
        }
        _coEditorController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text('AI: Berhasil disesuaikan dengan "$instruction"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveFoodDraftToLog() async {
    if (_draftFoodItems.isEmpty) return;

    setState(() => _isFoodSaving = true);
    try {
      final notifier = ref.read(nutritionStateProvider.notifier);
      for (var i = 0; i < _draftFoodItems.length; i++) {
        final item = _draftFoodItems[i];
        final scale = _portionScales[i] ?? 1.0;
        await notifier.logFood(
          mealType: _selectedMealType,
          foodItemId: item.foodItemId,
          foodName: item.foodName,
          servingQty: scale,
          servingUnit: '${item.portionDescription} (~${(item.estimatedGrams * scale).round()}g)',
          calories: item.calories * scale,
          proteinG: item.proteinG * scale,
          carbsG: item.carbsG * scale,
          fatG: item.fatG * scale,
          source: 'ai_smart_hub',
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('${_draftFoodItems.length} item berhasil dicatat ke $_selectedMealTitle!'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Gagal menyimpan makanan ke jurnal. Coba lagi.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFoodSaving = false);
    }
  }

  double get _totalCalories {
    double sum = 0.0;
    for (var i = 0; i < _draftFoodItems.length; i++) {
      sum += _draftFoodItems[i].calories * (_portionScales[i] ?? 1.0);
    }
    return sum;
  }

  double get _totalProtein {
    double sum = 0.0;
    for (var i = 0; i < _draftFoodItems.length; i++) {
      sum += _draftFoodItems[i].proteinG * (_portionScales[i] ?? 1.0);
    }
    return sum;
  }

  double get _totalCarbs {
    double sum = 0.0;
    for (var i = 0; i < _draftFoodItems.length; i++) {
      sum += _draftFoodItems[i].carbsG * (_portionScales[i] ?? 1.0);
    }
    return sum;
  }

  double get _totalFat {
    double sum = 0.0;
    for (var i = 0; i < _draftFoodItems.length; i++) {
      sum += _draftFoodItems[i].fatG * (_portionScales[i] ?? 1.0);
    }
    return sum;
  }

  // --- Workout Handlers ---
  void _startAiPlannedWorkout() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiWorkoutGeneratorModal(),
    );
  }

  void _startFreeformWorkout() {
    final text = _workoutFreeformController.text.trim();
    if (text.isEmpty) return;

    Navigator.pop(context);
    ActiveWorkoutSessionSheet.show(context, title: 'Sesi Bebas: $text');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFF0B0E14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0x3310B981))),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_task_rounded, color: Color(0xFF10B981), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pusat Aksi Cepat Cal',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            Text(
                              'Pindai Makanan, AI Co-Editor, & Latihan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Segmented Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.black,
                unselectedLabelColor: const Color(0xFF94A3B8),
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                tabs: const [
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restaurant_rounded, size: 14),
                        SizedBox(width: 4),
                        Flexible(child: Text('Pindai Makanan', overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fitness_center_rounded, size: 14),
                        SizedBox(width: 4),
                        Flexible(child: Text('Latihan Dunia', overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFoodHubTab(bottomInset),
                _buildWorkoutHubTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: FOOD HUB (SCAN, BARCODE, PROMPT, CO-EDITOR)
  // ==========================================
  Widget _buildFoodHubTab(double bottomInset) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Meal Slot Selector Chips
          Row(
            children: [
              const Text('Waktu Makan: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(width: 6),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildMealChip('breakfast', 'Sarapan'),
                      const SizedBox(width: 6),
                      _buildMealChip('lunch', 'Makan Siang'),
                      const SizedBox(width: 6),
                      _buildMealChip('dinner', 'Makan Malam'),
                      const SizedBox(width: 6),
                      _buildMealChip('snack', 'Camilan'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Scanner Launch Buttons (Camera & Barcode)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AiVisionFoodSheet(
                        mealType: _selectedMealType,
                        mealTitle: _selectedMealTitle,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151922),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x3310B981)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_rounded, color: Color(0xFF10B981), size: 18),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Pindai Kamera AI',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AiVisionFoodSheet(
                        mealType: _selectedMealType,
                        mealTitle: _selectedMealTitle,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151922),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF818CF8), size: 18),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Pindai Barcode',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Natural Language Text Entry Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF121620),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Color(0xFF10B981), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Deskripsi Makanan / Minuman Cepat',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Deskripsikan apa yang Anda santap, AI akan mengurai gramatur dan nutrisinya.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _foodTextController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cth: Nasi putih 1 porsi, dada ayam bakar 1 potong, tempe orek 2 sdm...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0B0E14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 10),
                // Quick Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Ide: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                      _buildSampleChip('Nasi Padang Rendang'),
                      _buildSampleChip('Soto Ayam & Nasi'),
                      _buildSampleChip('Telur Rebus 2 & Tempe'),
                      _buildSampleChip('Oatmeal & Pisang'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isFoodAnalyzing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(_isFoodAnalyzing ? 'Menganalisis Gizi...' : 'Hitung Nilai Gizi AI'),
                  onPressed: _isFoodAnalyzing ? null : _analyzeFoodText,
                ),
              ],
            ),
          ),

          if (_foodError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_foodError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ),
          ],

          // ==========================================
          // PRE-INPUT NUTRITIONAL REVIEW POP-UP / CARD
          // WITH "EDIT PAKAI DESKRIPSI MAKANAN" (AI CO-EDITOR)
          // ==========================================
          if (_draftFoodItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F131E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x4D10B981), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pop-up Kandungan & Nilai Gizi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0x2610B981),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: const Color(0x4D10B981)),
                        ),
                        child: const Text(
                          'Siap Diverifikasi',
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Macro Overview Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF080A10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacroPill('KALORI', '${_totalCalories.round()} kkal', const Color(0xFF10B981)),
                        _buildMacroPill('PROTEIN', '${_totalProtein.round()}g', const Color(0xFF818CF8)),
                        _buildMacroPill('KARBO', '${_totalCarbs.round()}g', const Color(0xFFF59E0B)),
                        _buildMacroPill('LEMAK', '${_totalFat.round()}g', const Color(0xFFFB7185)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Itemized List with Portions
                  const Text('Daftar Bahan Terdeteksi:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  for (var i = 0; i < _draftFoodItems.length; i++) ...[
                    _buildDraftItemRow(i),
                    if (i < _draftFoodItems.length - 1) const SizedBox(height: 8),
                  ],

                  const SizedBox(height: 14),

                  // AI CO-EDITOR: "EDIT PAKAI DESKRIPSI MAKANAN"
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141926),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x33818CF8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit_note_rounded, color: Color(0xFF818CF8), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Edit Pakai Deskripsi Makanan (AI Co-Editor)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF818CF8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ketik instruksi koreksi jika ada porsi atau bahan yang perlu diubah.',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _coEditorController,
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Cth: "Nasi ganti setengah porsi, tanpa kuah santan"',
                                  hintStyle: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  isDense: true,
                                  filled: true,
                                  fillColor: Color(0xFF090B12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                onSubmitted: (val) => _applyCoEditorInstruction(val),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF818CF8),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _applyCoEditorInstruction(_coEditorController.text),
                              child: const Text('Koreksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildCoEditorChip('Nasi 1/2 Porsi', 'Nasi kurangi setengah'),
                              _buildCoEditorChip('Ayam Tanpa Kulit', 'Ayam tanpa kulit'),
                              _buildCoEditorChip('Tanpa Kuah/Minyak', 'Tanpa kuah dan tanpa minyak'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Confirm Save Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isFoodSaving ? null : _saveFoodDraftToLog,
                    child: _isFoodSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text(
                            'Kunci & Simpan ${_draftFoodItems.length} Item ke $_selectedMealTitle',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealChip(String type, String title) {
    final isSelected = _selectedMealType == type;
    return ChoiceChip(
      label: Text(title, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: const Color(0xFF10B981),
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white70),
      backgroundColor: const Color(0xFF151922),
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedMealType = type;
            _selectedMealTitle = title;
          });
        }
      },
    );
  }

  Widget _buildSampleChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          _foodTextController.text = text;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2433),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(text, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ),
      ),
    );
  }

  Widget _buildCoEditorChip(String label, String prompt) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 10)),
        backgroundColor: const Color(0xFF090B12),
        side: const BorderSide(color: Color(0x33818CF8)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        onPressed: () => _applyCoEditorInstruction(prompt),
      ),
    );
  }

  Widget _buildMacroPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget _buildDraftItemRow(int index) {
    final item = _draftFoodItems[index];
    final scale = _portionScales[index] ?? 1.0;
    final finalCalories = (item.calories * scale).round();
    final finalGrams = (item.estimatedGrams * scale).round();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF151924),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.foodName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                    Text(
                      '~${finalGrams}g • P: ${(item.proteinG * scale).toStringAsFixed(1)}g, C: ${(item.carbsG * scale).toStringAsFixed(1)}g, F: ${(item.fatG * scale).toStringAsFixed(1)}g',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              Text('$finalCalories kkal', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('Skala Porsi: ', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              Expanded(
                child: Slider(
                  value: scale,
                  min: 0.25,
                  max: 3.0,
                  divisions: 11,
                  activeColor: const Color(0xFF10B981),
                  inactiveColor: Colors.white10,
                  label: '${scale.toStringAsFixed(2)}x',
                  onChanged: (val) {
                    setState(() {
                      _portionScales[index] = val;
                    });
                  },
                ),
              ),
              Text('${scale.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: WORKOUT HUB (AI PLANNER, FREEFORM, CATALOG WITH PHOTOS)
  // ==========================================
  Widget _buildWorkoutHubTab() {
    // Filter exercises
    final filteredExercises = _allExercises.where((ex) {
      if (_selectedMuscleFilter != 'Semua') {
        if (_selectedMuscleFilter == 'Dada' && ex.targetMuscle.toLowerCase() != 'chest') return false;
        if (_selectedMuscleFilter == 'Punggung' && ex.targetMuscle.toLowerCase() != 'back') return false;
        if (_selectedMuscleFilter == 'Kaki' && !['quads', 'hamstrings', 'calves', 'glutes'].contains(ex.targetMuscle.toLowerCase())) return false;
        if (_selectedMuscleFilter == 'Bahu' && ex.targetMuscle.toLowerCase() != 'shoulders') return false;
        if (_selectedMuscleFilter == 'Lengan' && !['biceps', 'triceps'].contains(ex.targetMuscle.toLowerCase())) return false;
      }
      final query = _exerciseSearchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        return ex.name.toLowerCase().contains(query) || ex.targetMuscle.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. AI Duration-Based Workout Planner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF18182E), Color(0xFF111422)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x33818CF8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timer_outlined, color: Color(0xFF818CF8), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI Workout Generator Sesuai Durasi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pilih rentang waktu & alat yang tersedia, AI akan menyusun rangkaian latihan terstruktur.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
                const SizedBox(height: 12),

                // Duration Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Waktu: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      const SizedBox(width: 4),
                      _buildDurationChip(15, '15 Menit (Kilat)'),
                      const SizedBox(width: 4),
                      _buildDurationChip(30, '30 Menit (Fokus)'),
                      const SizedBox(width: 4),
                      _buildDurationChip(45, '45 Menit'),
                      const SizedBox(width: 4),
                      _buildDurationChip(60, '60 Menit (Full)'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Equipment Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Alat: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      const SizedBox(width: 4),
                      _buildEquipmentChip('gym', 'Mesin Gym & Barbel'),
                      const SizedBox(width: 6),
                      _buildEquipmentChip('dumbbell', 'Dumbbell'),
                      const SizedBox(width: 6),
                      _buildEquipmentChip('bodyweight', 'Beban Tubuh'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF818CF8),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.flash_on_rounded, size: 16),
                  label: Text(
                    'Rancang Sesi $_selectedDurationMinutes Menit dengan AI',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  onPressed: _startAiPlannedWorkout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Freeform Workout Description Logger
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF121620),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: Color(0xFF10B981), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Deskripsi Latihan Bebas',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Catat latihan yang baru saja Anda lakukan secara bebas.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _workoutFreeformController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Cth: Push up 4 set 15 reps, bench press 3 set 10 reps 60kg...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFF0B0E14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Mulai / Catat Sesi Latihan Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: _startFreeformWorkout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Movement Catalog with Real Photos & Full Guidance Modal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Katalog Semua Gerakan di Dunia',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                    ),
                    Text(
                      'Setiap gerakan dilengkapi foto asli & panduan langkah lengkap',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x2610B981),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${filteredExercises.length} Gerakan',
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Field
          TextField(
            controller: _exerciseSearchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Cari nama gerakan (cth: Squat, Bench Press, Pull Up)...',
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF64748B)),
              filled: true,
              fillColor: const Color(0xFF151922),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
          const SizedBox(height: 10),

          // Muscle Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMuscleChip('Semua'),
                _buildMuscleChip('Dada'),
                _buildMuscleChip('Punggung'),
                _buildMuscleChip('Bahu'),
                _buildMuscleChip('Kaki'),
                _buildMuscleChip('Lengan'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_isLoadingExercises)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF10B981))))
          else ...[
            for (final ex in filteredExercises) ...[
              _buildExerciseCard(ex),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDurationChip(int minutes, String label) {
    final isSelected = _selectedDurationMinutes == minutes;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: const Color(0xFF818CF8),
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white70),
      backgroundColor: const Color(0xFF151922),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onSelected: (val) {
        if (val) setState(() => _selectedDurationMinutes = minutes);
      },
    );
  }

  Widget _buildEquipmentChip(String category, String label) {
    final isSelected = _selectedEquipmentCategory == category;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: const Color(0xFF10B981),
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white70),
      backgroundColor: const Color(0xFF151922),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onSelected: (val) {
        if (val) setState(() => _selectedEquipmentCategory = category);
      },
    );
  }

  Widget _buildMuscleChip(String name) {
    final isSelected = _selectedMuscleFilter == name;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(name, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: const Color(0xFF10B981),
        labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white70),
        backgroundColor: const Color(0xFF151922),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        onSelected: (val) {
          setState(() => _selectedMuscleFilter = name);
        },
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseItem ex) {
    final imageUrl = ExerciseDetailModal.getExerciseImageUrl(ex.name, ex.targetMuscle, ex.category);

    return InkWell(
      onTap: () {
        ExerciseDetailModal.show(context, exercise: ex);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF141824),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Row(
          children: [
            // Exercise Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 64,
                  height: 64,
                  color: const Color(0xFF1E2433),
                  child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF10B981)),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Exercise Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0x26818CF8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ex.targetMuscle,
                          style: const TextStyle(color: Color(0xFF818CF8), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ex.equipment.isNotEmpty ? ex.equipment : ex.category,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.touch_app_rounded, size: 11, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text(
                        'Ketuk untuk foto & panduan langkah lengkap',
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
