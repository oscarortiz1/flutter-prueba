import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'db_provider.dart';
import 'sync_service.dart';

class AuthService {
  final ApiService _api;

  /// Allow injecting ApiService for testing; default uses singleton.
  AuthService({ApiService? api}) : _api = api ?? ApiService.instance;

  /// Notifier used by router to refresh when login state changes.
  static final ValueNotifier<bool> authLoggedIn = ValueNotifier<bool>(false);

  static const _tokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _loggedInKey = 'is_logged_in';
  static const _emailKey = 'user_email';

  // API login; stores token and marks logged in
  Future<bool> login(String email, String password) async {
    final resp = await _api.post('/auth/login', data: {'email': email, 'password': password});
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final token = resp.data['access_token'] as String?;
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setBool(_loggedInKey, true);
        await prefs.setString(_emailKey, email);
  authLoggedIn.value = true;
        return true;
      }
    }
    return false;
  }

  // API register
  Future<bool> register(String name, String email, String password) async {
    final resp = await _api.post('/auth/register', data: {'name': name, 'email': email, 'password': password});
    return resp.statusCode == 201 || resp.statusCode == 200;
  }

  Future<String?> requestOtp(String email, String password) async {
    try {
      // call the dedicated OTP endpoint (backend returns { code: '1234' })
      final resp = await _api.post('/auth/request-otp', data: {'email': email, 'password': password});
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = resp.data;
        if (data is Map) {
          final code = data['code'] ?? data['otp'] ?? data['otp_code'];
          return code?.toString();
        }
        if (data is String) return data;
      }
      return null;
    } catch (e) {
      // propagate network/Dio errors as string so caller can show a helpful message
      // print for developer diagnostics
      // ignore: avoid_print
      print('AuthService.requestOtp error: $e');
      rethrow;
    }
  }

  Future<bool> verifyOtp(String email, String code) async {
    final resp = await _api.post('/auth/verify-otp', data: {'email': email, 'code': code});
    if ((resp.statusCode == 200 || resp.statusCode == 201) && resp.data['access_token'] != null) {
      final token = resp.data['access_token'] as String;
      final refresh = resp.data['refresh_token'] as String?;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      if (refresh != null) await prefs.setString(_refreshTokenKey, refresh);
      await prefs.setBool(_loggedInKey, true);
      await prefs.setString(_emailKey, email);
      authLoggedIn.value = true;
      return true;
    }
    return false;
  }

  /// Try to restore session on app start by refreshing access token with stored refresh token.
  Future<bool> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);
    final refresh = prefs.getString(_refreshTokenKey);
    if (email == null || refresh == null) return false;
    final resp = await _api.post('/auth/refresh', data: {'email': email, 'refresh_token': refresh});
    if ((resp.statusCode == 200 || resp.statusCode == 201) && resp.data['access_token'] != null) {
      await prefs.setString(_tokenKey, resp.data['access_token'] as String);
      await prefs.setBool(_loggedInKey, true);
      authLoggedIn.value = true;
      return true;
    }
    // refresh failed: clear stored tokens
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_loggedInKey);
    await prefs.remove(_emailKey);
    authLoggedIn.value = false;
    return false;
  }

  Future<bool> refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);
    final refresh = prefs.getString(_refreshTokenKey);
    if (email == null || refresh == null) return false;
    final resp = await _api.post('/auth/refresh', data: {'email': email, 'refresh_token': refresh});
    if ((resp.statusCode == 200 || resp.statusCode == 201) && resp.data['access_token'] != null) {
      await prefs.setString(_tokenKey, resp.data['access_token'] as String);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_loggedInKey);
    await prefs.remove(_emailKey);
  authLoggedIn.value = false;
    // Stop background sync and clear any queued flag
    try {
      SyncService().stopAutoSync();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sync_queued');
    } catch (e) {}

    // Clear local sqlite DB when the user logs out
    try {
      await DBProvider().clearAll();
    } catch (e) {
      // ignore errors during cleanup
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> setLoggedIn(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_emailKey, email);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  /// Fetch the current user's profile using stored access token (calls /auth/me)
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final resp = await _api.get('/auth/me');
      if (resp.statusCode == 200) {
        return Map<String, dynamic>.from(resp.data as Map);
      }
    } catch (e) {
      // ignore - will return null
    }
    return null;
  }

  Future<bool> updateProfile({String? name, String? email, String? password}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (password != null && password.isNotEmpty) body['password'] = password;
    try {
      final resp = await _api.patch('/users/me', data: body);
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
