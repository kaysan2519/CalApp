import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cal/core/network/api_client.dart';
import 'package:cal/core/storage/token_storage.dart';
import 'package:cal/features/auth/data/auth_repository.dart';
import 'package:cal/features/auth/domain/auth_models.dart';
import 'package:cal/features/auth/presentation/auth_state_notifier.dart';

class InMemoryTokenStorage extends TokenStorage {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }
}

class StaticAuthRepository extends AuthRepository {
  StaticAuthRepository({
    required super.apiClient,
    required super.tokenStorage,
    required this.user,
  });

  final User? user;

  @override
  Future<User?> getCurrentUser() async => user;
}

class StaticAuthStateNotifier extends AuthStateNotifier {
  StaticAuthStateNotifier(super.repository, User? user) {
    state = AsyncValue.data(user);
  }
}

List<Override> loggedOutAppOverrides() {
  final tokenStorage = InMemoryTokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final repository = StaticAuthRepository(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
    user: null,
  );

  return [
    tokenStorageProvider.overrideWithValue(tokenStorage),
    apiClientProvider.overrideWithValue(apiClient),
    authRepositoryProvider.overrideWithValue(repository),
    authStateProvider.overrideWith((ref) => StaticAuthStateNotifier(repository, null)),
  ];
}
