import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? userType; // Added this parameter

  const ForgotPasswordScreen({super.key, this.userType});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _emailError;

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    setState(() => _emailError = null);

    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      return;
    }
    if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);
    // Pass userType to service to match signature
    final result =
        await _authService.requestPasswordReset(email, widget.userType);
    setState(() => _isLoading = false);

    if (result['success']) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            email: email,
            userType: widget.userType, // Pass it along
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Enter your email to receive a verification code.',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() => _emailError = null),
              decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: const OutlineInputBorder(),
                  errorText: _emailError),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSendOtp,
                style: AppTheme.primaryButton(),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Send Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
