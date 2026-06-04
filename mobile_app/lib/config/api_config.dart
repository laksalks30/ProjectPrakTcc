// ============ FILE: mobile_app/lib/config/api_config.dart ============
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ApiConfig {
  // Override saat run: flutter run --dart-define=API_HOST=192.168.x.x
  // Emulator Android pakai 10.0.2.2, device fisik pakai IP komputer/LAN.
  static const String _hostOverride = String.fromEnvironment('API_HOST', defaultValue: '');

  // static String get _baseHost {
  //   if (_hostOverride.isNotEmpty) {
  //     return _hostOverride;
  //   }

  //   if (kIsWeb) {
  //     return 'localhost';
  //   }

  //   return '192.168.18.218';
  // }

  static String get authBaseUrl => 'https://auth-service-25672599351.asia-southeast2.run.app/api/auth';
  static String get medBaseUrl => 'https://medication-service-25672599351.asia-southeast2.run.app/api';

  static const Duration timeout = Duration(seconds: 15);

  static Map<String, String> headers(String? token) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }
}
