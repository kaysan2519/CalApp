import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_state_notifier.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _pages = <(String, String)>[
    ('Tujuan dan aktivitas', 'Pilih arah yang terasa sesuai. Target berat badan boleh dikosongkan.'),
    ('Pengalaman latihan', 'Atur frekuensi dan hari latihan yang cocok dengan rutinitasmu.'),
    ('Peralatan yang tersedia', 'Pilih peralatan yang benar-benar bisa kamu gunakan.'),
    ('Preferensi makanan', 'Beritahu kami pilihan, alergi, atau pantanganmu. Semua boleh dilewati.'),
    ('Kebutuhan khusus', 'Tambahkan batasan aktivitas bila ada, lalu tinjau estimasi awalmu.'),
  ];

  final _pageController = PageController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _preferencesController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _restrictionsController = TextEditingController();
  final _limitationsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Set<String> _selectedDays = {};
  final Set<String> _selectedEquipment = {};

  int _page = 0;
  int _trainingDays = 3;
  String _goal = 'maintain';
  String _activity = 'moderate';
  String _experience = 'beginner';
  bool _initialized = false;
  bool _saving = false;
  String? _error;

  static const _days = <String, String>{
    'monday': 'Sen',
    'tuesday': 'Sel',
    'wednesday': 'Rab',
    'thursday': 'Kam',
    'friday': 'Jum',
    'saturday': 'Sab',
    'sunday': 'Min',
  };

  static const _equipment = <String>[
    'Tanpa alat',
    'Dumbbell',
    'Resistance band',
    'Mesin gym',
    'Barbell',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _preferencesController.dispose();
    _allergiesController.dispose();
    _restrictionsController.dispose();
    _limitationsController.dispose();
    super.dispose();
  }

  void _initializeFromProfile() {
    if (_initialized) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    _initialized = true;
    _goal = user.goal;
    _activity = user.activityLevel;
    _experience = user.trainingExperience;
    _trainingDays = user.trainingDaysPerWeek.clamp(1, 7).toInt();
    _ageController.text = user.age.toString();
    _heightController.text = user.heightCm?.toString() ?? '';
    _weightController.text = user.weightKg?.toString() ?? '';
    _targetWeightController.text = user.targetWeightKg?.toString() ?? '';
    _selectedDays.addAll(user.trainingSchedule);
    _selectedEquipment.addAll(user.availableEquipment);
    _preferencesController.text = user.foodPreferences.join(', ');
    _allergiesController.text = user.allergies.join(', ');
    _restrictionsController.text = user.dietaryRestrictions.join(', ');
    _limitationsController.text = user.activityLimitations ?? '';
  }

  List<String> _commaList(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final targetText = _targetWeightController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    final heightCm = double.tryParse(_heightController.text.trim());
    final weightKg = double.tryParse(_weightController.text.trim());
    final payload = <String, dynamic>{
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'goal': _goal,
      'activityLevel': _activity,
      'targetWeightKg': targetText.isEmpty ? null : double.parse(targetText),
      'trainingExperience': _experience,
      'trainingDaysPerWeek': _trainingDays,
      'trainingSchedule': _selectedDays.toList(),
      'availableEquipment': _selectedEquipment.toList(),
      'foodPreferences': _commaList(_preferencesController.text),
      'allergies': _commaList(_allergiesController.text),
      'dietaryRestrictions': _commaList(_restrictionsController.text),
      'activityLimitations': _limitationsController.text.trim().isEmpty ? null : _limitationsController.text.trim(),
      'onboardingCompleted': true,
    };

    try {
      await ref.read(authStateProvider.notifier).updateProfile(payload);
      if (mounted) {
        final editing = GoRouterState.of(context).uri.queryParameters['edit'] == 'true';
        context.go(editing ? '/profile' : '/recommendations');
      }
    } catch (error) {
      final cause = error is DioException ? error.error : null;
      setState(() => _error = cause is ApiException
          ? cause.message
          : 'Profil belum tersimpan. Periksa koneksi lalu coba lagi.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    } else {
      _saveAndContinue();
    }
  }

  void _previous() {
    if (_page > 0) _pageController.previousPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    _initializeFromProfile();
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text(GoRouterState.of(context).uri.queryParameters['edit'] == 'true' ? 'Perbarui profil' : 'Profil personal')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: (_page + 1) / _pages.length, minHeight: 5),
                    const SizedBox(height: 18),
                    Text(_pages[_page].$1, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(_pages[_page].$2, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.darkTextSecondary)),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (value) => setState(() => _page = value),
                  children: [
                    _buildGoalPage(),
                    _buildTrainingPage(),
                    _buildEquipmentPage(),
                    _buildFoodPage(),
                    _buildReviewPage(user.name),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Row(
                  children: [
                    if (_page > 0)
                      OutlinedButton(onPressed: _saving ? null : _previous, child: const Text('Kembali'))
                    else
                      const SizedBox.shrink(),
                    const Spacer(),
                    TextButton(onPressed: _saving ? null : _next, child: Text(_page == _pages.length - 1 ? 'Lewati opsional' : 'Lewati bagian')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saving ? null : _next,
                      child: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_page == _pages.length - 1 ? 'Simpan profil' : 'Lanjut'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageBody(List<Widget> children) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: children,
      );

  Widget _buildGoalPage() => _pageBody([
        TextFormField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Umur (tahun)'),
          validator: (value) {
            final number = int.tryParse(value?.trim() ?? '');
            if (number == null || number < 18 || number > 120) return 'Masukkan umur 18–120 tahun';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _heightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?'))],
          decoration: const InputDecoration(labelText: 'Tinggi badan (cm)'),
          validator: (value) {
            final number = double.tryParse(value?.trim() ?? '');
            if (number == null || number < 100 || number > 250) return 'Masukkan tinggi 100–250 cm';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?'))],
          decoration: const InputDecoration(labelText: 'Berat badan saat ini (kg)'),
          validator: (value) {
            final number = double.tryParse(value?.trim() ?? '');
            if (number == null || number < 30 || number > 300) return 'Masukkan berat 30–300 kg';
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _goal,
          decoration: const InputDecoration(labelText: 'Tujuan utama'),
          items: const [
            DropdownMenuItem(value: 'lose', child: Text('Menurunkan berat badan')),
            DropdownMenuItem(value: 'maintain', child: Text('Menjaga berat badan')),
            DropdownMenuItem(value: 'fitness', child: Text('Meningkatkan kebugaran')),
            DropdownMenuItem(value: 'muscle', child: Text('Membangun otot')),
            DropdownMenuItem(value: 'gain', child: Text('Menaikkan berat badan')),
          ],
          onChanged: (value) => setState(() => _goal = value ?? _goal),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _targetWeightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?'))],
          decoration: const InputDecoration(labelText: 'Target berat badan (kg)', hintText: 'Opsional'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            final number = double.tryParse(value.trim());
            if (number == null || number < 30 || number > 300) return 'Masukkan target 30–300 kg';
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _activity,
          decoration: const InputDecoration(labelText: 'Aktivitas harian'),
          items: const [
            DropdownMenuItem(value: 'sedentary', child: Text('Lebih banyak duduk')),
            DropdownMenuItem(value: 'light', child: Text('Aktivitas ringan')),
            DropdownMenuItem(value: 'moderate', child: Text('Cukup aktif')),
            DropdownMenuItem(value: 'heavy', child: Text('Aktif')),
            DropdownMenuItem(value: 'very_heavy', child: Text('Sangat aktif')),
          ],
          onChanged: (value) => setState(() => _activity = value ?? _activity),
        ),
      ]);

  Widget _buildTrainingPage() => _pageBody([
        DropdownButtonFormField<String>(
          initialValue: _experience,
          decoration: const InputDecoration(labelText: 'Pengalaman latihan'),
          items: const [
            DropdownMenuItem(value: 'beginner', child: Text('Pemula')),
            DropdownMenuItem(value: 'intermediate', child: Text('Menengah')),
            DropdownMenuItem(value: 'advanced', child: Text('Berpengalaman')),
          ],
          onChanged: (value) => setState(() => _experience = value ?? _experience),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: _trainingDays,
          decoration: const InputDecoration(labelText: 'Frekuensi latihan per minggu'),
          items: List.generate(7, (index) => DropdownMenuItem(value: index + 1, child: Text('${index + 1} hari'))),
          onChanged: (value) => setState(() => _trainingDays = value ?? _trainingDays),
        ),
        const SizedBox(height: 20),
        const Text('Hari yang biasanya tersedia', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _days.entries.map((day) => FilterChip(
                label: Text(day.value),
                selected: _selectedDays.contains(day.key),
                onSelected: (selected) => setState(() {
                  selected ? _selectedDays.add(day.key) : _selectedDays.remove(day.key);
                }),
              )).toList(),
        ),
      ]);

  Widget _buildEquipmentPage() => _pageBody([
        const Text('Pilih yang tersedia. Kamu bisa mengubahnya kapan saja.', style: TextStyle(color: AppColors.darkTextSecondary)),
        const SizedBox(height: 16),
        ..._equipment.map((equipment) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(equipment),
              value: _selectedEquipment.contains(equipment),
              onChanged: (selected) => setState(() {
                selected == true ? _selectedEquipment.add(equipment) : _selectedEquipment.remove(equipment);
              }),
            )),
      ]);

  Widget _buildFoodPage() => _pageBody([
        _textListField(_preferencesController, 'Preferensi makanan', 'Contoh: vegetarian, masakan rumahan'),
        const SizedBox(height: 14),
        _textListField(_allergiesController, 'Alergi', 'Pisahkan beberapa item dengan koma'),
        const SizedBox(height: 14),
        _textListField(_restrictionsController, 'Pantangan makanan', 'Opsional'),
      ]);

  Widget _buildReviewPage(String name) => _pageBody([
        _metricCard('Estimasi awal', 'Target kalori dan makro dihitung dengan rumus di aplikasi berdasarkan data profil. Nilainya bisa ditinjau dan diedit.'),
        const SizedBox(height: 14),
        _metricCard('Rencana latihan', 'Rekomendasi mempertimbangkan tujuan, pengalaman, frekuensi, dan peralatan yang kamu pilih.'),
        const SizedBox(height: 14),
        TextFormField(
          controller: _limitationsController,
          minLines: 3,
          maxLines: 5,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Batasan aktivitas atau kebutuhan khusus',
            hintText: 'Opsional. Hindari membagikan informasi yang tidak ingin disimpan di profil.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        Text('Profil ini tersimpan untuk $name dan dapat diperbarui dari halaman profil.', style: const TextStyle(color: AppColors.darkTextSecondary)),
      ]);

  Widget _textListField(TextEditingController controller, String label, String hint) => TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, hintText: hint),
        textCapitalization: TextCapitalization.sentences,
      );

  Widget _metricCard(String title, String content) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(color: AppColors.darkTextSecondary, height: 1.4)),
          ]),
        ),
      );
}
