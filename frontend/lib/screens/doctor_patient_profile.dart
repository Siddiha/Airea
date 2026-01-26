import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'doctor_home_page.dart';
import 'doctor_patient_summary.dart';

class DoctorPatientProfile extends StatelessWidget {
  final String patientName;

  const DoctorPatientProfile({
    super.key,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),

              // Edit medical details button
              _buildMenuButton(
                context,
                'Edit medical details',
                onTap: () {
                  // TODO: Navigate to edit medical details
                },
              ),
              const SizedBox(height: 16),

              // Edit allergic conditions button
              _buildMenuButton(
                context,
                'Edit allergic conditions',
                onTap: () {
                  // TODO: Navigate to edit allergic conditions
                },
              ),
              const SizedBox(height: 16),

              // View medical reports button
              _buildMenuButton(
                context,
                'View medical reports',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorPatientSummary(
                        patientName: patientName,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // View allergic conditions button
              _buildMenuButton(
                context,
                'View allergic conditions',
                onTap: () {
                  // TODO: Navigate to view allergic conditions
                },
              ),
              const SizedBox(height: 16),

              // Log out button
              _buildMenuButton(
                context,
                'Log out',
                onTap: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildMenuButton(BuildContext context, String text, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: AppTheme.primaryTeal,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoctorHomePage(),
                    ),
                  );
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.home,
                      color: Colors.black87,
                      size: 24,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
