import 'package:flutter/material.dart';
import 'patient_homeScreen.dart';
import 'device_screen.dart';
import 'patient_edit_emergency_contact.dart';
import 'patient_edit_medical_details.dart';
import 'patient_view_past_medical_reports.dart';



class PatientProfileFrame extends StatelessWidget {
  const PatientProfileFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 35),
              
              // Pass the label and the class name (or null if not created yet)
              _buildMenuButton(context, 'Edit medical details', EditMedicalInfo()), 
              _buildMenuButton(context, 'Edit emergency contact', EditEmergencyInfo()),
              _buildMenuButton(context, 'View medical reports', ViewReportsScreen()),
              _buildMenuButton(context, 'View allergic conditions', null),
              _buildMenuButton(context, 'Log out', null), // Example: LogoutPage()
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientHomeScreen(),
                ),
              );
              break;
            case 1:
              // Navigate to Device Screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeviceScreen(),
                ),
              );
              break;
            case 2:
              // Navigate to Trends & Summary
              // TODO: Implement PatientSummaryPage
              break;
          }
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wifi_tethering),
            label: 'Device',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Trends &\nsummary',
          ),
        ],
      ),
    );
  }

  /// Helper method that accepts the button text and the destination class
  Widget _buildMenuButton(BuildContext context, String title, Widget? destinationPage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: destinationPage == null 
            ? () {}
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => destinationPage),
                );
              },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF66A399),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}