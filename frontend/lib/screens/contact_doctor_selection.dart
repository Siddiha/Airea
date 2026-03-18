import 'package:airea_cough_monitor/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'contact_doctor.dart';
import 'doctor_details.dart';
import '../services/doctor_patient_service.dart';
import 'patient_homeScreen.dart';

class ContactDoctorSelection extends StatelessWidget {
  const ContactDoctorSelection({super.key});

  Future<void> _openDoctorDetails(BuildContext context) async {
    final doctors = await DoctorPatientService.getConnectedDoctors();
    if (!context.mounted) return;
    if (doctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No connected doctor found.')),
      );
      return;
    }
    final doc = doctors.first;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorDetails(
          doctorName: doc['doctorName'] ?? 'Unknown',
          phoneNumber: doc['phoneNumber'] ?? '',
          specialization: doc['specialization'] ?? '',
          hospital: doc['hospital'] ?? '',
          doctorCode: doc['doctorCode'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Doctor')),
      bottomNavigationBar: _bottomNav(context, 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _button(
              'Contact Doctor',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ContactDoctor(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _button(
              "Doctor's details",
              () => _openDoctorDetails(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: AppTheme.secondaryButton(),
        onPressed: onTap,
        child: Text(text),
      ),
    );
  }

  BottomNavigationBar _bottomNav(BuildContext context, int index) {
    return BottomNavigationBar(
      currentIndex: index,
      selectedItemColor: AppTheme.primaryTeal,
      unselectedItemColor: Colors.grey,
      onTap: (i) {
        if (i == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
            (route) => false,
          );
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.wifi),
          label: 'Device',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: 'Trends & summary',
        ),
      ],
    );
  }
}