import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _otpError;

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    final digitsOnly = RegExp(r'^\d+$');

    setState(() => _otpError = null);

    if (otp.isEmpty) {
      setState(() => _otpError = 'Please enter the verification code');
      return;
    }
    if (!digitsOnly.hasMatch(otp)) {
      setState(() => _otpError = 'Code must contain only digits');
      return;
    }
    if (otp.length < 6) {
      setState(() => _otpError = 'Code must be exactly 6 digits');
      return;
    }

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
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() => _otpError = null),
              decoration: InputDecoration(
                  hintText: '000000',
                  border: const OutlineInputBorder(),
                  errorText: _otpError),
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
