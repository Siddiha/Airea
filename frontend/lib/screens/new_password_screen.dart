import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import 'role_selection_page.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _passError;
  String? _confirmError;

  Future<void> _handleUpdate() async {
    final pass = _passController.text;
    final confirm = _confirmController.text;
    bool hasError = false;

    setState(() {
      _passError = null;
      _confirmError = null;
    });

    if (pass.isEmpty) {
      setState(() => _passError = 'Password is required');
      hasError = true;
    } else if (pass.length < 6) {
      setState(() => _passError = 'Password must be at least 6 characters');
      hasError = true;
    }

    if (confirm.isEmpty) {
      setState(() => _confirmError = 'Please confirm your password');
      hasError = true;
    } else if (pass != confirm) {
      setState(() => _confirmError = 'Passwords do not match');
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);
    final result = await _authService.updatePassword(pass);
    setState(() => _isLoading = false);

    if (result['success']) {
      // Success! Go back to Role Selection (clear history)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password reset successful! Please login.')),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Create a new password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _passController,
              obscureText: true,
              onChanged: (_) => setState(() => _passError = null),
              decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  errorText: _passError),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _confirmController,
              obscureText: true,
              onChanged: (_) => setState(() => _confirmError = null),
              decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  errorText: _confirmError),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleUpdate,
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
                    : const Text('Update Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
