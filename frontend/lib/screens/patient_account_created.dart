import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

      // Register the user with email and password
      final result = await authService.register(
        registrationData.email,
        registrationData.password,
      );

      if (result['success']) {
        // If registration is successful we can also persist other profile info locally
        print('User registered successfully');
        if (widget.registrationData?.medicalDetails != null) {
          await ProfileService.saveMedicalDetails(widget.registrationData!.medicalDetails!);
        }
        // Save full name to SharedPreferences
        final fullName = registrationData.fullName ?? '';
        print('Registration fullName: "$fullName"');
        if (fullName.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_full_name', fullName);
        }

        // Create patient row in Spring Boot DB with the actual full name.
        // At this point the Supabase auth user exists but the patients table
        // row does not yet — calling register here creates it with the correct name.
        if (fullName.isNotEmpty) {
          try {
            final resp = await http.post(
              Uri.parse('${ApiConfig.baseUrl}/auth/register'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'email': registrationData.email,
                'password': registrationData.password,
                'fullName': fullName,
              }),
            ).timeout(const Duration(seconds: 10));
            print('Spring Boot register response: ${resp.statusCode} ${resp.body}');
          } catch (e) {
            print('Spring Boot register failed: $e');
          }

          // Upsert to Supabase patients table (handles timing race with DB trigger)
          try {
            await Supabase.instance.client
                .from('patients')
                .upsert(
                  {'email': registrationData.email, 'full_name': fullName},
                  onConflict: 'email',
                );
            print('Supabase patients upsert succeeded');
          } catch (e) {
            print('Supabase patients upsert failed: $e');
          }
        }
        setState(() {
          _isLoading = false;
          _success = true;
          _message = 'User account created\nsuccessfully';
        });

        // Auto-navigate after 2 seconds
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const PatientHomeScreen()),
            (route) => false,
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _success = false;
          _message = result['message'] ?? 'Failed to create account';
        });
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
                    color: _success ? AppTheme.normalGreen : Colors.red.shade300,
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