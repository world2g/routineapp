// lib/services/auth_service.dart
//
// Supabase Authentication wrapper.
// Supabase persists the session automatically via secure storage.
//
// Supabase project setup:
//   • Disable "Email confirmations" in Authentication → Settings if you want
//     users to log in immediately after registration (recommended for dev).
 
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../models/user.dart';
 
class AuthService {
  final _supabase = Supabase.instance.client;
 
  // ── Register ────────────────────────────────────────────────────────────────
  Future<AppUser> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email:    email,
        password: password,
        data:     {'username': username},
      );
      if (response.user == null) throw const AuthException('Registration failed.');
      if (response.session == null) {
        throw const AuthException(
            'Account created. Please check your email to confirm before signing in.');
      }
      return AppUser.fromSupabase(response.user!);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(_mapError(e.toString()));
    }
  }
 
  // ── Login ───────────────────────────────────────────────────────────────────
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email:    email,
        password: password,
      );
      if (response.user == null) throw const AuthException('Login failed.');
      return AppUser.fromSupabase(response.user!);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(_mapError(e.toString()));
    }
  }
 
  // ── Logout ──────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
 
  // ── Restore session ─────────────────────────────────────────────────────────
  // Supabase persists the session automatically; just read currentUser.
  AppUser? getCurrentUser() {
    final user = _supabase.auth.currentUser;
    return user == null ? null : AppUser.fromSupabase(user);
  }
 
  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _mapError(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login credentials') || m.contains('invalid_credentials')) {
      return 'Invalid email or password.';
    }
    if (m.contains('email not confirmed') || m.contains('email_not_confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (m.contains('user already registered') || m.contains('already registered')) {
      return 'An account with this email already exists.';
    }
    if (m.contains('password should be at least') || m.contains('weak_password')) {
      return 'Password must be at least 6 characters.';
    }
    if (m.contains('unable to validate email') || m.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }
    if (m.contains('too many requests') || m.contains('rate limit')) {
      return 'Too many attempts. Please try again later.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
 
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
 
  @override
  String toString() => message;
}
 
