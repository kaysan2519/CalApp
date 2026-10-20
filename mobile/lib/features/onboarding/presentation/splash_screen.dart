import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_state_notifier.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (auth.hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, color: AppColors.warning, size: 44),
                const SizedBox(height: 14),
                const Text(
                  'Belum dapat terhubung ke server Cal.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Target Server: ${ApiClient.defaultBaseUrl}\nPastikan server backend di port 4000 sudah aktif.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: () => ref.read(authStateProvider.notifier).checkAuth(),
                  label: const Text('Coba Hubungkan Ulang'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    await ref.read(tokenStorageProvider).clearTokens();
                    ref.read(authStateProvider.notifier).reset();
                    if (context.mounted) context.go('/welcome');
                  },
                  child: const Text('Lanjutkan ke Halaman Selamat Datang'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!auth.isLoading) {
      final user = auth.valueOrNull;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(user == null
            ? '/welcome'
            : user.onboardingCompleted
                ? '/today'
                : '/onboarding');
      });
    }

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
            stops: [0.0, 0.45],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.bolt_rounded, size: 50, color: Colors.black),
              ),
              const SizedBox(height: 20),
              Text(
                'Cal',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kebiasaan sehat, satu langkah setiap hari',
                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13.5),
              ),
              if (auth.isLoading) ...[
                const SizedBox(height: 32),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
