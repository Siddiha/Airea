import 'package:airea_cough_monitor/config/app_theme.dart';
import 'package:flutter/material.dart';
import '../services/doctor_patient_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'patient_homeScreen.dart';

class DoctorDetails extends StatelessWidget {
  final String doctorName;
  final String phoneNumber;
  final String specialization;
  final String hospital;
  final String doctorCode;

  const DoctorDetails({
    super.key,
    required this.doctorName,
    required this.phoneNumber,
    required this.specialization,
    required this.hospital,
    required this.doctorCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor's details")),
      bottomNavigationBar: const PatientBottomNav(currentIndex: 0),
      body: Center(
        child:SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40),
            ),
            const SizedBox(height: 10),
            Text(
              doctorName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              doctorCode,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            _infoCard('Mobile Number', phoneNumber.isNotEmpty ? phoneNumber : 'Not provided'),
            _infoCard('Specializations', specialization.isNotEmpty ? specialization : 'Not specified'),
            _infoCard('Hospital', hospital.isNotEmpty ? hospital : 'Not specified'),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: () => _showDisconnectConfirmation(context),
                style: AppTheme.dangerButton(),
                child: const Text('Disconnect Doctor'),
              ),
            ),
          ],
        ),
        
        ),
      ),
    );
  }

  void _showDisconnectConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Disconnect Doctor',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to disconnect from Dr. $doctorName? '
          'You will no longer be monitored by this doctor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // close dialog
              final success = await DoctorPatientService.disconnectFromDoctor(doctorCode);
              if (context.mounted) {
                if (success) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
                    (route) => false,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to disconnect. Please try again.')),
                  );
                }
              }
            },
            style: AppTheme.dangerButton(),
            child: const Text('Yes, Disconnect'),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return SizedBox(
      width:320,
      child:Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(value),
        ],
      ),
      ),
    );
  }

}