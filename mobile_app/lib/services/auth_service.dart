// ============ FILE: mobile_app/lib/services/auth_service.dart ============
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  // ─── Login ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.authBaseUrl}/login'),
            headers: ApiConfig.headers(null),
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(ApiConfig.timeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final token = body['data']['token'];
        final userData = body['data']['user'];

        // Simpan ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user', jsonEncode(userData));

        return {
          'success': true,
          'user': User.fromJson(userData),
          'token': token,
        };
      }

      return {
        'success': false,
        'message': body['message'] ?? 'Login gagal',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server: ${e.toString()}',
      };
    }
  }

  // ─── Register ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.authBaseUrl}/register'),
            headers: ApiConfig.headers(null),
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'phone': phone,
            }),
          )
          .timeout(ApiConfig.timeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 201 || body['success'] == true) {
        return {'success': true, 'message': 'Registrasi berhasil!'};
      }

      return {
        'success': false,
        'message': body['message'] ?? 'Registrasi gagal',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server: ${e.toString()}',
      };
    }
  }

  // ─── Logout ─────────────────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      await http
          .post(
            Uri.parse('${ApiConfig.authBaseUrl}/logout'),
            headers: ApiConfig.headers(token),
          )
          .timeout(ApiConfig.timeout);
    } catch (_) {}

    await prefs.remove('token');
    await prefs.remove('user');
  }

  // ─── Get Profile ────────────────────────────────────────────────
  Future<User?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.authBaseUrl}/profile'),
            headers: ApiConfig.headers(token),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          return User.fromJson(body['data']['user']);
        }
      }
    } catch (_) {}
    return null;
  }

  // ─── Get stored token ───────────────────────────────────────────
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ─── Get stored user ───────────────────────────────────────────
  Future<User?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr == null) return null;
    try {
      return User.fromJson(jsonDecode(userStr));
    } catch (_) {
      return null;
    }
  }
}
