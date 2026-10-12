import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'auth_state_notifier.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController(text: '170');
  final _weightController = TextEditingController(text: '65');

  String _gender = 'neutral';
  String _activityLevel = 'moderate';
  String _goal = 'maintain';

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final age = int.parse(_ageController.text.trim());
      final height = double.tryParse(_heightController.text.trim()) ?? 170.0;
      final weight = double.tryParse(_weightController.text.trim()) ?? 65.0;

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
      setState(() {
        _errorMessage = err.toString().contains('Email sudah terdaftar')
            ? 'Email sudah terdaftar. Silakan gunakan email lain atau masuk.'
            : 'Gagal mendaftar. Pastikan semua data terisi dengan benar.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrasi Cal'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Buat Akun & Target Nutrisi',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Target kalori dan makro akan dihitung otomatis sesuai rumus ilmiah Mifflin-St Jeor.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.darkTextSecondary,
                      ),
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Nama wajib diisi';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email wajib diisi';
                    if (!val.contains('@')) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Kata Sandi (Minimal 8 Karakter)',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 8) return 'Kata sandi minimal 8 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Age Gate Field
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Usia (Tahun)',
                    prefixIcon: Icon(Icons.cake_outlined),
                    helperText: 'Aplikasi ini hanya untuk pengguna berusia minimal 18 tahun.',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Usia wajib diisi';
                    final parsed = int.tryParse(val.trim());
                    if (parsed == null) return 'Masukkan angka usia yang valid';
                    if (parsed < 18) return 'Usia minimal harus 18 tahun untuk menggunakan aplikasi.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tinggi (cm)',
                          prefixIcon: Icon(Icons.height_rounded),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Wajib diisi';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Berat (kg)',
                          prefixIcon: Icon(Icons.monitor_weight_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Wajib diisi';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Kelamin (untuk Rumus BMR)',
                    prefixIcon: Icon(Icons.wc_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Laki-laki')),
                    DropdownMenuItem(value: 'female', child: Text('Perempuan')),
                    DropdownMenuItem(value: 'neutral', child: Text('Lainnya / Netral')),
                  ],
                  onChanged: (val) => setState(() => _gender = val ?? 'neutral'),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _activityLevel,
                  decoration: const InputDecoration(
                    labelText: 'Tingkat Aktivitas Harian',
                    prefixIcon: Icon(Icons.directions_run_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'sedentary', child: Text('Sedentari (Jarang Olahraga)')),
                    DropdownMenuItem(value: 'light', child: Text('Ringan (Olahraga 1-3 Hari/Minggu)')),
                    DropdownMenuItem(value: 'moderate', child: Text('Sedang (Olahraga 3-5 Hari/Minggu)')),
                    DropdownMenuItem(value: 'heavy', child: Text('Berat (Olahraga 6-7 Hari/Minggu)')),
                  ],
                  onChanged: (val) => setState(() => _activityLevel = val ?? 'moderate'),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _goal,
                  decoration: const InputDecoration(
                    labelText: 'Tujuan Nutrisi',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'lose', child: Text('Turunkan Berat Badan (Defisit Aman)')),
                    DropdownMenuItem(value: 'maintain', child: Text('Jaga Berat Badan (Maintenance)')),
                    DropdownMenuItem(value: 'gain', child: Text('Naikkan Berat / Massa Otot (Surplus)')),
                  ],
                  onChanged: (val) => setState(() => _goal = val ?? 'maintain'),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('Daftar & Hitung Target'),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun? '),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Masuk'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
