// Talks to your Django REST Framework backend.
// Expected Django endpoints:
//   POST /api/auth/register/  → { id, username, email, token }
//   POST /api/auth/login/     → { id, username, email, token }
//   POST /api/auth/logout/    → 200 OK
//
// The token is stored locally in SharedPreferences so the user stays
// logged in across app restarts.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  // ── Change this to your Django server address ──────────────────────────────
  static const String _baseUrl = 'http://192.168.1.100:8000/api/auth';
  // ───────────────────────────────────────────────────────────────────────────

  static const _keyToken    = 'auth_token';
  static const _keyUserId   = 'user_id';
  static const _keyUsername = 'user_username';
  static const _keyEmail    = 'user_email';

  // ── Register ────────────────────────────────────────────────────────────────
  Future<AppUser> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = AppUser.fromJson(data);
      await _saveSession(user);
      return user;
    }

    // Surface the Django validation error to the UI
    final error = _extractError(response.body);
    throw AuthException(error);

    
  }

  // ── Login 
  Future<AppUser> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = AppUser.fromJson(data);
      await _saveSession(user);
      return user;
    }

    throw AuthException(_extractError(response.body));
  }

  // ── Logout 
  Future<void> logout(String token) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/logout/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
    } catch (_) {
      // Even if the server call fails, clear the local session
    }
    await _clearSession();
  }

  // ── Restore session on app start 
  Future<AppUser?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token    = prefs.getString(_keyToken);
    final userId   = prefs.getInt(_keyUserId);
    final username = prefs.getString(_keyUsername);
    final email    = prefs.getString(_keyEmail);

    if (token == null || userId == null || username == null || email == null) {
      return null;
    }

    return AppUser(id: userId, username: username, email: email, token: token);
  }

  // ── Helpers 
  Future<void> _saveSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken,    user.token);
    await prefs.setInt(_keyUserId,   user.id);
    await prefs.setString(_keyUsername, user.username);
    await prefs.setString(_keyEmail,    user.email);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyEmail);
  }

  String _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        // Django often returns {"non_field_errors": ["..."]}
        final values = decoded.values.toList();
        if (values.isNotEmpty) {
          final first = values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          return first.toString();
        }
      }
    } catch (_) {}
    return 'An error occurred. Please try again.';
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}