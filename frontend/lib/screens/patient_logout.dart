import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'role_selection_page.dart';

/// Widget screen that lets the current user log out and returns to role selection.
class PatientLogoutScreen extends StatefulWidget {
  const PatientLogoutScreen({Key? key}) : super(key: key);

  @override
  State<PatientLogoutScreen> createState() => _PatientLogoutScreenState();
}

class _PatientLogoutScreenState extends State<PatientLogoutScreen> {
  bool _loading = false;

  Future<void> _performLogout() async {
    setState(() => _loading = true);
    try {
      await PatientLogout().execute(context);
      // PatientLogout navigates away; no further action needed here.
    } catch (_) {
      // ignore and allow UI to show non-blocking feedback if desired
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Log out',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'You are about to sign out of your account. If you want to use Airea again, you will need to log in with your credentials.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _performLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66A399),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Log out', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper class to perform logout and navigate back to the role selection page.
class PatientLogout {
  final AuthService _auth;

  PatientLogout([AuthService? auth]) : _auth = auth ?? AuthService();

  /// Performs logout and then clears navigation to the role selection screen.
  Future<void> execute(BuildContext context) async {
    try {
      // Clear old non-user-scoped profile data to prevent leakage
      await ProfileService.clearLegacyLocalData();
      await _auth.logout();
    } catch (_) {
      // ignore logout errors and continue to navigate
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
      (route) => false,
    );
  }

  /// Convenience static method for callers that previously used a top-level function.
  static Future<void> logoutAndGoToRoleSelection(BuildContext context) {
    return PatientLogout().execute(context);
  }
}
