// ============ FILE: mobile_app/lib/providers/auth_provider.dart ============
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  String? _token;
  bool _isLoading = true;
  bool _isAuthenticated = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _loadStoredAuth();
  }

  /// Auto-login dari SharedPreferences
  Future<void> _loadStoredAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _token = await _authService.getToken();
      _user = await _authService.getStoredUser();

      if (_token != null && _user != null) {
        _isAuthenticated = true;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  /// Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await _authService.login(email, password);

    if (result['success'] == true) {
      _user = result['user'] as User;
      _token = result['token'] as String;
      _isAuthenticated = true;
      notifyListeners();
    }

    return result;
  }

  /// Register
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    return await _authService.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _token = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Refresh profile dari server
  Future<void> refreshProfile() async {
    final profile = await _authService.getProfile();
    if (profile != null) {
      _user = profile;
      notifyListeners();
    }
  }
}
