import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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

  Future<void> _handleUpdate() async {
    final pass = _passController.text;
    final confirm = _confirmController.text;

    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password must be at least 6 characters')));
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authService.updatePassword(pass);
    setState(() => _isLoading = false);

    if (result['success']) {
      // Success! Go back to Login Screen (clear history)
      Navigator.of(context).popUntil((route) => route.isFirst);
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
              decoration: const InputDecoration(
                  labelText: 'New Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Confirm Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleUpdate,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Update Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
