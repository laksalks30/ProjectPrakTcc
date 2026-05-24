// ============ FILE: mobile_app/lib/config/api_config.dart ============
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Untuk Android Emulator, gunakan 10.0.2.2 sebagai pengganti localhost
  // Untuk device fisik, ganti dengan IP komputer Anda (misal: 192.168.x.x)
  static const String _baseHost = kIsWeb ? 'localhost' : '127.0.0.1';

  static const String authBaseUrl = 'http://$_baseHost:8001/api/auth';
  static const String medBaseUrl = 'http://$_baseHost:8002/api';

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
