import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import 'auth_state_notifier.dart';

/// Multi-step registration wizard. Each field gets its own dedicated screen
/// with a progress bar, title, subtitle, and a "Lanjut" (Continue) button.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  // Per-step form keys so validation is scoped to the current step only.
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(8, (_) => GlobalKey<FormState>());

  String _gender = 'neutral';
  String _activityLevel = 'moderate';
  String _goal = 'maintain';

  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  static const _totalSteps = 8;

  // Step metadata: (icon, title, subtitle)
  static const _stepInfo = <(IconData, String, String)>[
    (Icons.person_outline_rounded, 'Siapa namamu?', 'Nama ini akan ditampilkan di profilmu.'),
    (Icons.email_outlined, 'Email & Kata Sandi', 'Untuk masuk ke akunmu nanti.'),
    (Icons.cake_outlined, 'Berapa usiamu?', 'Cal hanya untuk pengguna 18 tahun ke atas.'),
    (Icons.wc_rounded, 'Jenis Kelamin', 'Digunakan untuk menghitung kebutuhan kalori (BMR).'),
    (Icons.height_rounded, 'Tinggi Badan', 'Dalam sentimeter. Untuk kalkulasi target nutrisi.'),
    (Icons.monitor_weight_outlined, 'Berat Badan', 'Berat saat ini dalam kilogram.'),
    (Icons.directions_run_rounded, 'Aktivitas Harian', 'Seberapa aktif keseharianmu?'),
    (Icons.flag_outlined, 'Tujuan Nutrisi', 'Apa yang ingin kamu capai?'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // ── Navigation ──────────────────────────────────────────────────────────

  void _goNext() {
    final formKey = _formKeys[_currentStep];
    if (formKey.currentState != null && !formKey.currentState!.validate()) {
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleRegister();
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/welcome');
    }
  }

  // ── Submit Registration ─────────────────────────────────────────────────

  Future<void> _handleRegister() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final age = int.parse(_ageController.text.trim());
      final height = double.parse(_heightController.text.trim());
      final weight = double.parse(_weightController.text.trim());

      await ref.read(authStateProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            age: age,
            gender: _gender,
            heightCm: height,
            weightKg: weight,
            activityLevel: _activityLevel,
            goal: _goal,
          );

      if (mounted) {
        context.go('/today');
      }
    } catch (err) {
      final cause = err is DioException ? err.error : null;
      setState(() => _errorMessage = cause is ApiException
          ? cause.message
          : 'Gagal mendaftar. Periksa koneksi internet dan coba lagi.');
      // Scroll back to step 0 if it's a duplicate email type error.
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, title, subtitle) = _stepInfo[_currentStep];
    final isLastStep = _currentStep == _totalSteps - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F2420),
              AppColors.darkBackground,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
          children: [
            // ── Top bar: back + progress ──
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isSubmitting ? null : _goBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Kembali',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: (_currentStep) / _totalSteps,
                          end: (_currentStep + 1) / _totalSteps,
                        ),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: AppColors.darkBorder,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentStep + 1}/$_totalSteps',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.darkTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Header: icon + title + subtitle ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Error banner ──
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── PageView with each step ──
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() {
                  _currentStep = index;
                  _errorMessage = null;
                }),
                children: [
                  _buildNameStep(),
                  _buildEmailPasswordStep(),
                  _buildAgeStep(),
                  _buildGenderStep(),
                  _buildHeightStep(),
                  _buildWeightStep(),
                  _buildActivityStep(),
                  _buildGoalStep(),
                ],
              ),
            ),

            // ── Bottom: continue button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _goNext,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              isLastStep ? 'Daftar & Mulai' : 'Lanjut',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  if (_currentStep == 0) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Sudah punya akun? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Masuk'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // ── Step Builders ───────────────────────────────────────────────────────

  Widget _stepPadding({required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: child,
    );
  }

  // Step 1: Name
  Widget _buildNameStep() {
    return _stepPadding(
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                hintText: 'Contoh: Budi Santoso',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Nama wajib diisi';
                if (val.trim().length < 2) return 'Nama minimal 2 karakter';
                return null;
              },
              onFieldSubmitted: (_) => _goNext(),
            ),
          ],
        ),
      ),
    );
  }

  // Step 2: Email & Password
  Widget _buildEmailPasswordStep() {
    return _stepPadding(
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'contoh@email.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Email wajib diisi';
                if (!val.contains('@') || !val.contains('.')) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Kata Sandi',
                hintText: 'Minimal 8 karakter',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (val) {
                if (val == null || val.length < 8) {
                  return 'Kata sandi minimal 8 karakter';
                }
                return null;
              },
              onFieldSubmitted: (_) => _goNext(),
            ),
          ],
        ),
      ),
    );
  }

  // Step 3: Age
  Widget _buildAgeStep() {
    return _stepPadding(
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _ageController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Usia (tahun)',
                hintText: '18',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Usia wajib diisi';
                final parsed = int.tryParse(val.trim());
                if (parsed == null) return 'Masukkan angka usia yang valid';
                if (parsed < 18) return 'Kamu harus berusia minimal 18 tahun';
                if (parsed > 120) return 'Masukkan usia yang valid (maks 120)';
                return null;
              },
              onFieldSubmitted: (_) => _goNext(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aplikasi ini hanya untuk pengguna berusia minimal 18 tahun.',
                      style: TextStyle(
                        color: AppColors.info.withValues(alpha: 0.85),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 4: Gender
  Widget _buildGenderStep() {
    return _stepPadding(
      child: Form(
        key: _formKeys[3],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GenderOption(
              value: 'male',
              label: 'Laki-laki',
              icon: Icons.male_rounded,
              selected: _gender == 'male',
              onTap: () => setState(() => _gender = 'male'),
            ),
            const SizedBox(height: 10),
            _GenderOption(
              value: 'female',
              label: 'Perempuan',
              icon: Icons.female_rounded,
              selected: _gender == 'female',
              onTap: () => setState(() => _gender = 'female'),
            ),
            const SizedBox(height: 10),
            _GenderOption(
              value: 'neutral',
              label: 'Lainnya / Tidak ingin menyebutkan',
              icon: Icons.transgender_rounded,
              selected: _gender == 'neutral',
              onTap: () => setState(() => _gender = 'neutral'),
            ),
            const SizedBox(height: 12),
            Text(
              'Jenis kelamin digunakan untuk rumus BMR (Mifflin–St Jeor). '
              'Pilihan "Lainnya" menggunakan rata-rata kedua rumus.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkTextSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 5: Height
  Widget _buildHeightStep() {
    return _stepPadding(
      child: Form(
        key: _formKeys[4],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _heightController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,1})?')),
              ],
              decoration: const InputDecoration(
                labelText: 'Tinggi Badan (cm)',
                hintText: '170',
                prefixIcon: Icon(Icons.height_rounded),
                suffixText: 'cm',
              ),
              validator: (val) {
                final parsed = double.tryParse(val?.trim() ?? '');
                if (parsed == null) return 'Masukkan tinggi badan';
                if (parsed < 100 || parsed > 250) return 'Tinggi harus antara 100–250 cm';
                return null;
              },
              onFieldSubmitted: (_) => _goNext(),
            ),
          ],
        ),
      ),
    );
  }

  // Step 6: Weight
  Widget _buildWeightStep() {
    return _stepPadding(
      child: Form(
        key: _formKeys[5],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _weightController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,1})?')),
              ],
              decoration: const InputDecoration(
                labelText: 'Berat Badan (kg)',
                hintText: '65',
                prefixIcon: Icon(Icons.monitor_weight_outlined),
                suffixText: 'kg',
              ),
              validator: (val) {
                final parsed = double.tryParse(val?.trim() ?? '');
                if (parsed == null) return 'Masukkan berat badan';
                if (parsed < 30 || parsed > 300) return 'Berat harus antara 30–300 kg';
                return null;
              },
              onFieldSubmitted: (_) => _goNext(),
            ),
          ],
        ),
      ),
    );
  }

  // Step 7: Activity Level
  Widget _buildActivityStep() {
    const levels = <(String, String, String, IconData)>[
      ('sedentary', 'Sedentari', 'Lebih banyak duduk, jarang olahraga', Icons.weekend_outlined),
      ('light', 'Ringan', 'Olahraga ringan 1–3 hari/minggu', Icons.directions_walk_rounded),
      ('moderate', 'Cukup Aktif', 'Olahraga sedang 3–5 hari/minggu', Icons.directions_run_rounded),
      ('heavy', 'Aktif', 'Olahraga berat 6–7 hari/minggu', Icons.fitness_center_rounded),
    ];

    return _stepPadding(
      child: Form(
        key: _formKeys[6],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < levels.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _SelectionCard(
                label: levels[i].$2,
                description: levels[i].$3,
                icon: levels[i].$4,
                selected: _activityLevel == levels[i].$1,
                onTap: () => setState(() => _activityLevel = levels[i].$1),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Step 8: Goal
  Widget _buildGoalStep() {
    const goals = <(String, String, String, IconData)>[
      ('lose', 'Turunkan Berat', 'Defisit kalori yang aman & bertahap', Icons.trending_down_rounded),
      ('maintain', 'Jaga Berat', 'Kalori seimbang dengan aktivitas', Icons.balance_rounded),
      ('gain', 'Naikkan Berat', 'Surplus kalori untuk massa otot', Icons.trending_up_rounded),
    ];

    return _stepPadding(
      child: Form(
        key: _formKeys[7],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < goals.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _SelectionCard(
                label: goals[i].$2,
                description: goals[i].$3,
                icon: goals[i].$4,
                selected: _goal == goals[i].$1,
                onTap: () => setState(() => _goal = goals[i].$1),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Target kalori & makro akan dihitung otomatis dengan rumus Mifflin–St Jeor berdasarkan data yang kamu berikan.',
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
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

// ── Reusable Selection Widgets ──────────────────────────────────────────────

class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.darkBorder,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.darkTextSecondary,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.primary : null,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.darkBorder,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : AppColors.darkBorder.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppColors.primary : AppColors.darkTextSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.primary : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
