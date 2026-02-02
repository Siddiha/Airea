import 'package:airea_cough_monitor/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'contact_doctor.dart';
import 'doctor_details.dart';

class ContactDoctorSelection extends StatelessWidget {
  const ContactDoctorSelection({super.key});

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
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DoctorDetails(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryTeal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
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