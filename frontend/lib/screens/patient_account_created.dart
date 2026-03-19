import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../models/registration_data.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'patient_homescreen.dart';
import 'patient_create_account.dart';
import 'patient_login_page.dart';

class PatientAccountCreated extends StatefulWidget {
  final RegistrationData? registrationData;
  final List? allergies; // Keep for backward compatibility

  const PatientAccountCreated({
    super.key,
    this.registrationData,
    this.allergies,
  });

  @override
  State<PatientAccountCreated> createState() => _PatientAccountCreatedState();
}

class _PatientAccountCreatedState extends State<PatientAccountCreated> {
  bool _isLoading = true;
  String _message = 'User account created\nsuccessfully';
  bool _success = true;

  @override
  void initState() {
    super.initState();
    _registerUser();
  }

  Future<void> _registerUser() async {
    if (widget.registrationData == null) {
      // If no registration data, just show success
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final authService = AuthService();
      final registrationData = widget.registrationData!;

      // Register user in Supabase auth
      final result = await authService.register(
        registrationData.email,
        registrationData.password,
      );

      final String registerMessage = (result['message'] ?? '').toString();
      final bool supabaseSuccess = result['success'] == true;
      final bool alreadyRegistered =
          registerMessage.toLowerCase().contains('already registered') ||
              registerMessage.toLowerCase().contains('already exists');

      if (!supabaseSuccess && !alreadyRegistered) {
        setState(() {
          _isLoading = false;
          _success = false;
          _message = registerMessage.isNotEmpty
              ? registerMessage
              : 'Failed to create account';
        });
        return;
      }

      // Save local profile data
      if (registrationData.medicalDetails != null) {
        await ProfileService.saveMedicalDetails(
            registrationData.medicalDetails!);
      }

      final fullName = registrationData.fullName ?? '';
      if (fullName.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_full_name', fullName);
      }

      // Sync full profile to backend (single backend path)
      final backendOk = await _syncBackendRegistration(registrationData);
      if (!backendOk) {
        setState(() {
          _isLoading = false;
          _success = false;
          _message =
              'Account created, but profile sync failed. Please try again.';
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _success = true;
        _message = 'User account created\nsuccessfully';
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PatientHomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error during registration: $e');
      setState(() {
        _isLoading = false;
        _success = false;
        _message = 'An error occurred during registration';
      });
    }
  }

  Map<String, dynamic> _buildRegistrationPayload(RegistrationData data) {
    return {
      'email': data.email,
      'password': data.password,
      'fullName': data.fullName,
      'dateOfBirth': data.dateOfBirth,
      'gender': data.gender,
      'address': data.address,
      'emergencyContact': data.emergencyContact?.toJson(),
      'medicalDetails': data.medicalDetails?.toJson(),
      'allergies': data.allergies.map((a) => a.toJson()).toList(),
      'medicalReportPaths': data.medicalReportPaths,
    };
  }

  Future<bool> _syncBackendRegistration(RegistrationData data) async {
    try {
      final resp = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(_buildRegistrationPayload(data)),
          )
          .timeout(const Duration(seconds: 12));

      print('Spring Boot register response: ${resp.statusCode} ${resp.body}');

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        try {
          final regData = jsonDecode(resp.body);
          final token = regData['token'];
          if (token != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('backend_jwt_token', token as String);
          }
        } catch (_) {}
        return true;
      }

      return false;
    } catch (e) {
      print('Spring Boot register failed: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              if (_isLoading)
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppTheme.primaryTeal,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Creating your account...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                )
              else ...[
                // Success Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color:
                        _success ? AppTheme.normalGreen : Colors.red.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _success ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 80,
                  ),
                ),

                const SizedBox(height: 40),

                // Message
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const Spacer(),

                // Error Action Buttons
                if (!_success) ...[
                  // Try Sign Up Again Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PatientCreateAccount(),
                          ),
                          (route) => false,
                        );
                      },
                      style: AppTheme.primaryButton(),
                      child: const Text('Try Sign Up Again'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Go to Login Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PatientLoginPage(),
                          ),
                          (route) => false,
                        );
                      },
                      style: AppTheme.outlineButton(),
                      child: const Text('Go to Login'),
                    ),
                  ),
                ],
                // Success Close Button
                if (_success)
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PatientHomeScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.close, size: 28),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
