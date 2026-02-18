import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String get baseUrl => ApiConfig.baseUrl;

  // Register (email + password)
  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        await _storage.write(key: _tokenKey, value: data['token']);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // Login (email + password)
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await _storage.write(key: _tokenKey, value: data['token']);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Invalid credentials'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // Logout
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null;
  }

  // Get token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // ========== Password Reset ==========

  // Request password reset OTP
  Future<Map<String, dynamic>> requestPasswordReset(String email, String userType) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'userType': userType}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to send reset code'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // Verify OTP code
  Future<Map<String, dynamic>> verifyOtp(String email, String otp, String userType) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'otp': otp, 'userType': userType}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Invalid verification code'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // Reset password with OTP
  Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword, String userType) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
          'userType': userType,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to reset password'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // ========== Doctor Authentication ==========

  // Doctor Register (email + password)
  Future<Map<String, dynamic>> doctorRegister(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/doctor/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        await _storage.write(key: _tokenKey, value: data['token']);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // Doctor Login (email + password)
  Future<Map<String, dynamic>> doctorLogin(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/doctor/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await _storage.write(key: _tokenKey, value: data['token']);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Invalid credentials'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }
}