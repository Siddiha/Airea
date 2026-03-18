import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'patient_homeScreen.dart';
import 'device_screen.dart';
import 'patient_edit_emergency_contact.dart';
import 'patient_edit_medical_details.dart';
import '../services/profile_service.dart';
import '../config/api_config.dart';
import 'patient_logout.dart';
import 'patient_view_past_medical_reports.dart';
import 'patient_view_allergies.dart';

// 1. Import your new setup screen
import 'airea_setup_screen.dart';

class PatientProfileFrame extends StatelessWidget {
  const PatientProfileFrame({super.key});

  @override
  Widget build(BuildContext context) {
    // Added 'return' here to properly return the Scaffold
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

              // medical details button needs to load existing data before navigating
              Padding(
                padding: const EdgeInsets.only(bottom: 18.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      // fetch saved medical details
                      final details = await ProfileService.loadMedicalDetails();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditMedicalInfo(existingMedical: details),
                        ),
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
                    child: const Text(
                      'Edit medical details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 18.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      final contact = await ProfileService.loadEmergencyContact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditEmergencyInfo(existingContact: contact),
                        ),
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
                    child: const Text(
                      'Edit emergency contact',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              _buildMenuButton(
                  context, 'View medical reports', const ViewReportsScreen()),
              _buildMenuButton(context, 'View allergic conditions', const ViewAllergiesScreen()),

              // 2. Add the Connect Device button here
              _buildMenuButton(
                  context, 'Connect Airea Device', const AireaSetupScreen()),

              // View Patient ID Button
              Padding(
                padding: const EdgeInsets.only(bottom: 18.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      String? patientCode = prefs.getString('patient_code');
                      // If not cached, fetch from backend API
                      if (patientCode == null || patientCode.isEmpty) {
                        final user = Supabase.instance.client.auth.currentUser;
                        if (user != null) {
                          try {
                            final url = Uri.parse(
                                '${ApiConfig.baseUrl}/auth/patient/code?email=${Uri.encodeComponent(user.email!)}');
                            final resp = await http.get(url).timeout(const Duration(seconds: 10));
                            if (resp.statusCode == 200) {
                              final data = jsonDecode(resp.body);
                              if (data['code'] != null) {
                                patientCode = data['code'];
                                await prefs.setString('patient_code', patientCode!);
                              }
                            }
                          } catch (e) {
                            debugPrint('Error fetching patient code: $e');
                          }
                        }
                      }
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Your Patient ID'),
                            content: Text(
                              patientCode != null ? 'Your ID is $patientCode' : 'ID not found. Please re-login.',
                              style: const TextStyle(fontSize: 18),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF66A399),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'View ID',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),

              _buildMenuButton(context, 'Log out', const PatientLogoutScreen()),
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeviceScreen(),
                ),
              );
              break;
  case 2:
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
    ); // Added closing parenthesis and semicolon for Scaffold
  } // Added closing brace for build method

  Widget _buildMenuButton(
      BuildContext context, String title, Widget? destinationPage) {
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