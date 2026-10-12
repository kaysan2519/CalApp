import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _accessTokenKey = 'cal_access_token';
  static const _refreshTokenKey = 'cal_refresh_token';

  final FlutterSecureStorage _secureStorage;
  SharedPreferences? _prefs;

  TokenStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    try {
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (_) {
      // Fallback to shared_preferences if secure_storage is unavailable on platform
      await _initPrefs();
      await _prefs?.setString(_accessTokenKey, accessToken);
      await _prefs?.setString(_refreshTokenKey, refreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    try {
      final token = await _secureStorage.read(key: _accessTokenKey);
      if (token != null) return token;
    } catch (_) {}
    await _initPrefs();
    return _prefs?.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    try {
      final token = await _secureStorage.read(key: _refreshTokenKey);
      if (token != null) return token;
    } catch (_) {}
    await _initPrefs();
    return _prefs?.getString(_refreshTokenKey);
  }

  Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
    } catch (_) {}
    await _initPrefs();
    await _prefs?.remove(_accessTokenKey);
    await _prefs?.remove(_refreshTokenKey);
  }
}
