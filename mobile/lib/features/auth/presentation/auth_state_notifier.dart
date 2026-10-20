import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/auth_models.dart';

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AsyncValue<User?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(repository);
});

class AuthStateNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repository;

  AuthStateNotifier(this._repository) : super(const AsyncValue.loading()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    try {
      final user = await _repository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (_) {
      // If server unreachable or token invalid, clear stale tokens so user can proceed to welcome/login screen
      try {
        await _repository.tokenStorage.clearTokens();
      } catch (_) {}
      state = const AsyncValue.data(null);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.login(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required int age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    String? goal,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.register(
        email: email,
        password: password,
        name: name,
        age: age,
        gender: gender,
        heightCm: heightCm,
        weightKg: weightKg,
        activityLevel: activityLevel,
        goal: goal,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }

  Future<User> updateProfile(Map<String, dynamic> updates) async {
    final user = await _repository.updateProfile(updates);
    state = AsyncValue.data(user);
    return user;
  }

  Future<void> deleteAccount() async {
    await _repository.deleteAccount();
    state = const AsyncValue.data(null);
  }
}
