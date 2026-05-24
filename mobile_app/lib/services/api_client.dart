// ============ FILE: mobile_app/lib/services/api_client.dart ============
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Base API client yang menangani token dan error handling
class ApiClient {
  final String baseUrl;

  ApiClient(this.baseUrl);

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return ApiConfig.headers(token);
  }

  // ─── GET ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> get(String path, {Map<String, String>? params}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
    final headers = await _headers();
    final response = await http.get(uri, headers: headers).timeout(ApiConfig.timeout);
    return _handleResponse(response);
  }

  // ─── POST ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    final headers = await _headers();
    final response = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.timeout);
    return _handleResponse(response);
  }

  // ─── PUT ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    final headers = await _headers();
    final response = await http
        .put(
          Uri.parse('$baseUrl$path'),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.timeout);
    return _handleResponse(response);
  }

  // ─── DELETE ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> delete(String path) async {
    final headers = await _headers();
    final response = await http.delete(Uri.parse('$baseUrl$path'), headers: headers).timeout(ApiConfig.timeout);
    return _handleResponse(response);
  }

  // ─── Response Handler ───────────────────────────────────────────
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 401) {
      throw ApiException('Sesi berakhir. Silakan login kembali.', 401);
    }

    if (response.statusCode >= 400) {
      throw ApiException(
        body['message'] ?? body['detail']?['message'] ?? 'Terjadi kesalahan',
        response.statusCode,
      );
    }

    return body;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
