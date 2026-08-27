import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import '../models/auth.dart';

/// Manages the auth session: persists token / refreshToken / user in
/// shared_preferences, exposes a ChangeNotifier for UI, and performs the
/// single-flight token refresh on 401.
class Session extends ChangeNotifier {
  Session._();
  static final Session instance = Session._();

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'auth_user';

  String? _token;
  String? _refreshToken;
  CurrentUser? _user;
  bool _initialized = false;
  bool _restoring = false;
  Future<bool>? _refreshInFlight;

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  CurrentUser? get user => _user;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get initialized => _initialized;

  /// Restore a previously persisted session (called once at startup).
  Future<void> restore() async {
    if (_restoring) return;
    _restoring = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);
      final userJson = prefs.getString(_userKey);
      if (userJson != null && userJson.isNotEmpty) {
        try {
          _user = CurrentUser.fromJson(
              jsonDecode(userJson) as Map<String, dynamic>);
        } catch (_) {
          // Corrupt stored user — treat the session as invalid and clear
          // the persisted keys so the next launch starts fresh.
          _token = null;
          _refreshToken = null;
          _user = null;
          await prefs.remove(_tokenKey);
          await prefs.remove(_refreshTokenKey);
          await prefs.remove(_userKey);
        }
      }
    } finally {
      _initialized = true;
      _restoring = false;
      notifyListeners();
    }
  }

  Future<void> saveLogin({
    required String token,
    String? refreshToken,
    required CurrentUser user,
  }) async {
    _token = token;
    _refreshToken = refreshToken;
    _user = user;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Update the persisted user (e.g. after a profile picture change).
  Future<void> updateUser(CurrentUser user) async {
    _user = user;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Call POST /users/logout (best-effort) then clear local session.
  Future<void> logout() async {
    final token = _token;
    if (token != null) {
      try {
        await http
            .post(
              Uri.parse(AppConfig.url('/users/logout')),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Best-effort — the backend may be unreachable.
      }
    }
    await clear();
  }

  Future<void> clear() async {
    _token = null;
    _refreshToken = null;
    _user = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  /// Exchange the refresh token for a new token pair. Single-flight so
  /// concurrent 401s only trigger one refresh call.
  Future<bool> refresh() {
    final inflight = _refreshInFlight;
    if (inflight != null) return inflight;
    final future = _doRefresh();
    _refreshInFlight = future;
    return future.whenComplete(() => _refreshInFlight = null);
  }

  Future<bool> _doRefresh() async {
    final rt = _refreshToken;
    if (rt == null || rt.isEmpty) return false;
    try {
      final response = await http
          .post(
            Uri.parse(AppConfig.url('/users/refresh')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': rt}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return false;

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final api = body is Map<String, dynamic> ? body : null;
      if (api == null || api['success'] != true || api['data'] == null) {
        return false;
      }
      final auth =
          AuthResponse.fromJson(api['data'] as Map<String, dynamic>);
      await saveLogin(
        token: auth.token,
        refreshToken: auth.refreshToken,
        user: auth.user,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
