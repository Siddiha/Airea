import 'package:airea_cough_monitor/config/app_theme.dart';
import 'package:flutter/material.dart';

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
      bottomNavigationBar: _bottomNav(0),
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
          ],
        ),
        
        ),
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

  BottomNavigationBar _bottomNav(int index) {
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