import 'package:airea_cough_monitor/config/app_theme.dart';
import 'package:flutter/material.dart';
import '../services/doctor_patient_service.dart';
import 'patient_homeScreen.dart';

class ContactDoctor extends StatefulWidget {
  const ContactDoctor({super.key});

  @override
  State<ContactDoctor> createState() => _ContactDoctorState();
}

class _ContactDoctorState extends State<ContactDoctor> {
  String _phone = 'Loading...';
  String _hospital = 'Loading...';
  String _email = 'Loading...';
  String _doctorName = '';

  @override
  void initState() {
    super.initState();
    _loadDoctorContact();
  }

  Future<void> _loadDoctorContact() async {
    final doctors = await DoctorPatientService.getConnectedDoctors();
    if (mounted && doctors.isNotEmpty) {
      final doc = doctors.first;
      setState(() {
        _doctorName = doc['doctorName'] ?? 'Unknown';
        _phone = (doc['phoneNumber'] ?? '').toString().isNotEmpty
            ? doc['phoneNumber']
            : 'Not provided';
        _hospital = (doc['hospital'] ?? '').toString().isNotEmpty
            ? doc['hospital']
            : 'Not provided';
        _email = (doc['email'] ?? '').toString().isNotEmpty
            ? doc['email']
            : 'Not provided';
      });
    } else if (mounted) {
      setState(() {
        _phone = 'No doctor connected';
        _hospital = 'No doctor connected';
        _email = 'No doctor connected';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Doctor')),
      bottomNavigationBar: _bottomNav(0),

      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, 
              children: [
                const CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40),
                ),
                if (_doctorName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _doctorName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],

                const SizedBox(height: 30),

                _infoCard('Mobile Number', _phone),
                _infoCard('Clinic/Hospital', _hospital),
                _infoCard('Email', _email),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return SizedBox(
      width: 320, //forces horizontal centering
      child: Container(
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
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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