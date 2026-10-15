import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);
});

class AuthRepository {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  AuthRepository({required this.apiClient, required this.tokenStorage});

  Future<User> register({
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
    final response = await apiClient.post('/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
      'age': age,
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'activityLevel': activityLevel,
      'goal': goal,
    });

    final data = response.data['data'];
    await tokenStorage.saveTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );

    return User.fromJson(data['user']);
  }

  Future<User> login({required String email, required String password}) async {
    final response = await apiClient.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final data = response.data['data'];
    await tokenStorage.saveTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );

    return User.fromJson(data['user']);
  }

  Future<User?> getCurrentUser() async {
    final token = await tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await apiClient.get('/profile');
      final data = response.data['data'];
      final userJson = Map<String, dynamic>.from(data['user']);
      if (data['nutritionTargets'] != null) {
        userJson['nutritionTargets'] = data['nutritionTargets'];
      }
      return User.fromJson(userJson);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await tokenStorage.clearTokens();
        return null;
      }
      rethrow;
    }
  }

  Future<User> updateProfile(Map<String, dynamic> updates) async {
    final response = await apiClient.put('/profile', data: updates);
    final data = Map<String, dynamic>.from(response.data['data']);
    final userJson = Map<String, dynamic>.from(data['user']);
    if (data['nutritionTargets'] != null) {
      userJson['nutritionTargets'] = data['nutritionTargets'];
    }
    return User.fromJson(userJson);
  }

  Future<void> logout() async {
    try {
      final refreshToken = await tokenStorage.getRefreshToken();
      await apiClient.post('/auth/logout', data: {'refreshToken': refreshToken});
    } catch (_) {}
    await tokenStorage.clearTokens();
  }

  Future<Map<String, dynamic>> exportData() async {
    final response = await apiClient.get('/auth/export');
    return response.data['data'];
  }

  Future<void> deleteAccount() async {
    await apiClient.delete('/auth/account');
    await tokenStorage.clearTokens();
  }
}
