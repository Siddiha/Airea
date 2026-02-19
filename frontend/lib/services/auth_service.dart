import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
      if (res.user != null) return {'success': true, 'data': res.user};
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

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}
