import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyUserData = 'auth_user_data';
  static const String _keyRememberMe = 'auth_remember_me';
  static const String _keySavedPhone = 'auth_saved_phone';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Token management
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _prefs.setString(_keyAccessToken, accessToken);
    await _prefs.setString(_keyRefreshToken, refreshToken);
  }

  String? getAccessToken() {
    return _prefs.getString(_keyAccessToken);
  }

  String? getRefreshToken() {
    return _prefs.getString(_keyRefreshToken);
  }

  bool get hasValidToken {
    final token = getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // User caching
  Future<void> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _prefs.setString(_keyUserData, userJson);
  }

  UserModel? getUser() {
    final userJson = _prefs.getString(_keyUserData);
    if (userJson == null || userJson.isEmpty) return null;
    try {
      final decoded = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  // Remember me
  Future<void> saveRememberMe(bool remember, {String? phone}) async {
    await _prefs.setBool(_keyRememberMe, remember);
    if (remember && phone != null) {
      await _prefs.setString(_keySavedPhone, phone);
    } else {
      await _prefs.remove(_keySavedPhone);
    }
  }

  bool getRememberMe() {
    return _prefs.getBool(_keyRememberMe) ?? false;
  }

  String? getSavedPhone() {
    return _prefs.getString(_keySavedPhone);
  }

  // Logout / clear session
  Future<void> clearAuth() async {
    await _prefs.remove(_keyAccessToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyUserData);
  }
}
