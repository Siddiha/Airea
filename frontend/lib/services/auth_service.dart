import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Session storage keys
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userTypeKey = 'user_type';
  static const String _loginTimeKey = 'login_time';
  static const int _sessionDurationDays = 7;

  // Secure storage keys for credentials
  static const String _secureEmailKey = 'secure_email';
  static const String _securePasswordKey = 'secure_password';

  // --- Login Adapters ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    return _login(email, password);
  }

  Future<Map<String, dynamic>> doctorLogin(
      String email, String password) async {
    return _login(email, password);
  }

  Future<Map<String, dynamic>> _login(String email, String password) async {
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user != null) {
        // Save session AND credentials to device storage
        await _saveSession(res.user!.id, email, res.user!.userMetadata?['role'] ?? 'patient', password);
        return {'success': true, 'data': res.user};
      }
      return {'success': false, 'message': 'Login failed'};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // --- Registration Adapters ---
  Future<Map<String, dynamic>> register(String email, String password) async {
    return _register(email, password, 'patient');
  }

  Future<Map<String, dynamic>> doctorRegister(
      String email, String password) async {
    return _register(email, password, 'doctor');
  }

  Future<Map<String, dynamic>> _register(
      String email, String password, String role) async {
    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'role': role},
      );
      if (res.user != null) return {'success': true, 'data': res.user};
      return {'success': false, 'message': 'Registration failed'};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  // --- Forgot Password ---
  // Accepts userType to prevent crashes, even if Supabase doesn't strictly need it
  Future<Map<String, dynamic>> requestPasswordReset(String email,
      [String? userType]) async {
    try {
      await _supabase.auth.signInWithOtp(email: email, shouldCreateUser: false);
      return {'success': true, 'message': 'Code sent to $email'};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String token,
      [String? userType]) async {
    try {
      final res = await _supabase.auth
          .verifyOTP(type: OtpType.email, token: token, email: email);
      if (res.session != null) return {'success': true, 'message': 'Verified!'};
      return {'success': false, 'message': 'Invalid code'};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  // This fixes the error in reset_password_screen.dart
  Future<Map<String, dynamic>> resetPassword(
      String email, String otp, String newPassword,
      [String? userType]) async {
    try {
      // User is already logged in by verifyOtp, so we just update the user
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return {'success': true, 'message': 'Password updated successfully!'};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  // Helper for the new screen
  Future<Map<String, dynamic>> updatePassword(String newPassword) async {
    return resetPassword("", "", newPassword);
  }

  /// Logout from Supabase and clear all session data
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // Continue even if signOut fails
    }
    // Clear session from device storage
    await _clearSession();
  }

  /// Save session to SharedPreferences and credentials to SecureStorage
  Future<void> _saveSession(String userId, String email, String userType, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userTypeKey, userType);
    await prefs.setInt(_loginTimeKey, DateTime.now().millisecondsSinceEpoch);

    // Save credentials securely
    await _secureStorage.write(key: _secureEmailKey, value: email);
    await _secureStorage.write(key: _securePasswordKey, value: password);
  }

  /// Clear session from SharedPreferences (called on logout)
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userTypeKey);
    await prefs.remove(_loginTimeKey);

    // Clear credentials
    await _secureStorage.delete(key: _secureEmailKey);
    await _secureStorage.delete(key: _securePasswordKey);
  }

  /// Check if a valid session exists (within 7 days) AND restore Supabase auth if needed
  Future<bool> hasValidSession() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTime = prefs.getInt(_loginTimeKey);

    if (loginTime == null) return false;

    final elapsed = DateTime.now().millisecondsSinceEpoch - loginTime;
    final sevenDaysMs = _sessionDurationDays * 24 * 60 * 60 * 1000;

    if (elapsed >= sevenDaysMs) return false; // Session expired

    // Session is valid locally; try to restore Supabase auth
    await _restoreSupabaseSession();
    return true;
  }

  /// Restore Supabase authentication using stored credentials
  Future<void> _restoreSupabaseSession() async {
    try {
      final email = await _secureStorage.read(key: _secureEmailKey);
      final password = await _secureStorage.read(key: _securePasswordKey);

      if (email != null && password != null) {
        // Silent re-login to restore Supabase session
        await _supabase.auth.signInWithPassword(email: email, password: password);
      }
    } catch (_) {
      // If restore fails, session will be considered invalid
      // User will need to log in again
    }
  }

  /// Get cached user data without server call
  Future<Map<String, String>?> getCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    final email = prefs.getString(_userEmailKey);
    final userType = prefs.getString(_userTypeKey);

    if (userId == null || email == null || userType == null) return null;

    return {'userId': userId, 'email': email, 'userType': userType};
  }
}
