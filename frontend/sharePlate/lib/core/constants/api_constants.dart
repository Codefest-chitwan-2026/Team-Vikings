import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Configurable base host for easy testing on emulator, real device, or local backend.
  static String? _customBaseUrl;

  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url;
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    try {
      if (Platform.isAndroid) {
        // Android Emulator loops back to host machine via 10.0.2.2
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {
      // Fallback if Platform is not supported
    }
    return 'http://127.0.0.1:8000';
  }

  // Auth endpoints matching Django authentication app URLs
  static String get login => '$baseUrl/api/auth/login/';
  static String get logout => '$baseUrl/api/auth/logout/';
  static String get registerCustomer => '$baseUrl/api/auth/register/customer/';
  static String get registerBusiness => '$baseUrl/api/auth/register/business/';
  static String get registerNgo => '$baseUrl/api/auth/register/ngo/';
  static String get registerUser => '$baseUrl/api/auth/register/user/';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
