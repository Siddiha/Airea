import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'new_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String? userType; // Added this parameter

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.userType,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) return;

    setState(() => _isLoading = true);
    final result =
        await _authService.verifyOtp(widget.email, otp, widget.userType);
    setState(() => _isLoading = false);

    if (result['success']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NewPasswordScreen()),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Code')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text('Code sent to ${widget.email}'),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              textAlign: TextAlign.center,
              maxLength: 6,
              decoration: const InputDecoration(
                  hintText: '000000', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleVerify,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
