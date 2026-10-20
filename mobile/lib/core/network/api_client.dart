import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage: tokenStorage);
});

class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => 'ApiException($code): $message';
}

class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;

  static const String _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static String get defaultBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (kIsWeb) {
      return 'http://127.0.0.1:4000/api/v1';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000/api/v1';
    }
    return 'http://127.0.0.1:4000/api/v1';
  }

  Future<String?>? _refreshInProgress;

  ApiClient({
    required this.tokenStorage,
    String? baseUrl,
    Dio? customDio,
  }) : dio = customDio ?? Dio(BaseOptions(
          baseUrl: baseUrl ?? defaultBaseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
          headers: {'Content-Type': 'application/json'},
        )) {
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final request = error.requestOptions;

          // Auto-fallback for Android emulator vs local host/LAN
          if ((error.type == DioExceptionType.connectionTimeout ||
                  error.type == DioExceptionType.connectionError) &&
              request.extra['fallbackRetried'] != true &&
              request.baseUrl.contains('10.0.2.2')) {
            request.extra['fallbackRetried'] = true;
            try {
              final fallbackOptions = request.copyWith(
                baseUrl: request.baseUrl.replaceFirst('10.0.2.2', '127.0.0.1'),
              );
              final retried = await dio.fetch<dynamic>(fallbackOptions);
              return handler.resolve(retried);
            } catch (_) {
              try {
                final lanOptions = request.copyWith(
                  baseUrl: request.baseUrl.replaceFirst('10.0.2.2', '10.2.15.183'),
                );
                final lanRetried = await dio.fetch<dynamic>(lanOptions);
                return handler.resolve(lanRetried);
              } catch (_) {}
            }
          }

          final isAuthEndpoint = request.path.endsWith('/auth/login') ||
              request.path.endsWith('/auth/register') ||
              request.path.endsWith('/auth/refresh');
          if (error.response?.statusCode == 401 &&
              !isAuthEndpoint &&
              request.extra['authRetried'] != true) {
            try {
              final refreshFuture = _refreshInProgress ??= _refreshAccessToken();
              final accessToken = await refreshFuture;
              if (identical(_refreshInProgress, refreshFuture)) _refreshInProgress = null;
              if (accessToken != null) {
                request.headers['Authorization'] = 'Bearer $accessToken';
                request.extra['authRetried'] = true;
                final retried = await dio.fetch<dynamic>(request);
                return handler.resolve(retried);
              }
              await tokenStorage.clearTokens();
            } catch (_) {
              _refreshInProgress = null;
              await tokenStorage.clearTokens();
            }
          }
          final response = error.response;
          if (response?.data != null && response?.data is Map) {
            final errorData = response!.data['error'];
            if (errorData != null) {
              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  response: error.response,
                  error: ApiException(
                    code: errorData['code'] ?? 'SERVER_ERROR',
                    message: errorData['message'] ?? 'Terjadi kesalahan pada server',
                    statusCode: response.statusCode,
                    details: errorData['details'],
                  ),
                ),
              );
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = response.data?['data'];
    if (data is! Map || data['accessToken'] is! String || data['refreshToken'] is! String) {
      throw StateError('Refresh response was invalid.');
    }
    final accessToken = data['accessToken'] as String;
    await tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: data['refreshToken'] as String,
    );
    return accessToken;
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) {
    return dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return dio.delete<T>(path);
  }
}
