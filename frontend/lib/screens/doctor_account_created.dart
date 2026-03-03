import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/doctor_registration_data.dart';
import '../services/auth_service.dart';
import 'doctor_home_screen.dart';
import 'doctor_create_account.dart';
import 'doctor_login_page.dart';

class DoctorAccountCreated extends StatefulWidget {
  final DoctorRegistrationData? registrationData;

  const DoctorAccountCreated({
    super.key,
    this.registrationData,
  });

  @override
  State<DoctorAccountCreated> createState() => _DoctorAccountCreatedState();
}

class _DoctorAccountCreatedState extends State<DoctorAccountCreated> {
  bool _isLoading = true;
  String _message = 'Verification\ncompleted';
  bool _success = true;

  @override
  void initState() {
    super.initState();
    _registerDoctor();
  }

  Future<void> _registerDoctor() async {
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

      // Register the doctor with email and password
      final result = await authService.doctorRegister(
        registrationData.email,
        registrationData.password,
      );

      if (result['success']) {
        // If registration is successful, you could save additional doctor data here
        // For example, save name, specializations, etc. to a user profile service
        print('Doctor registered successfully');
        setState(() {
          _isLoading = false;
          _success = true;
          _message = 'Verification\ncompleted';
        });

        // Auto-navigate after 2 seconds
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DoctorHomeScreen()),
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
                      'Verification in progress...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                )
              else ...[
                // Success/Error Icon
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
                            builder: (context) => const DoctorCreateAccount(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Try Sign Up Again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                            builder: (context) => const DoctorLoginPage(),
                          ),
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryTeal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        side: const BorderSide(
                          color: AppTheme.primaryTeal,
                          width: 2,
                        ),
                      ),
                      child: const Text(
                        'Go to Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                            builder: (context) => const DoctorHomeScreen(),
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
