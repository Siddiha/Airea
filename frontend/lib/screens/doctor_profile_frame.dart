import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_doctor_details.dart';
import 'doctor_logout.dart';
import 'doctor_manage_patients_screen.dart';
import '../services/doctor_patient_service.dart';
import '../config/api_config.dart';

class DoctorProfileFrame extends StatelessWidget {
  const DoctorProfileFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 70,
        color: Colors.white,
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home, color: Colors.black87),
              SizedBox(height: 4),
              Text("Home", style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Profile",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),

              // Edit Additional Details Button
              _buildButton(context, "Edit additional details"),

              const SizedBox(height: 18),
              
              // Manage Connected Patients Button
              _buildButton(context, "Manage connected patients"),

              const SizedBox(height: 18),

              // View ID Button
              _buildButton(context, "View ID"),

              const SizedBox(height: 18),
              
              // Logout Button
              _buildButton(context, "Logout"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF66A399),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
        ),
        onPressed: () async {
          if (text == "Edit additional details") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EditDoctorDetails(),
              ),
            );
          } 
          else if (text == "Manage connected patients") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DoctorManagePatientsScreen(),
              ),
            );
          } 
          else if (text == "View ID") {
            String? doctorCode = await DoctorPatientService.getDoctorCode();
            // If not cached, fetch from backend API
            if (doctorCode == null || doctorCode.isEmpty) {
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null) {
                try {
                  final url = Uri.parse(
                      '${ApiConfig.baseUrl}/auth/doctor/code?email=${Uri.encodeComponent(user.email!)}');
                  final resp = await http.get(url).timeout(const Duration(seconds: 10));
                  if (resp.statusCode == 200) {
                    final data = jsonDecode(resp.body);
                    if (data['code'] != null) {
                      doctorCode = data['code'];
                      await DoctorPatientService.saveDoctorCode(doctorCode!);
                    }
                  }
                } catch (e) {
                  debugPrint('Error fetching doctor code: $e');
                }
              }
            }
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Your Doctor ID'),
                  content: Text(
                    doctorCode != null ? 'Your ID is $doctorCode' : 'ID not found. Please re-login.',
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
          }
          else if (text == "Logout") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DoctorLogoutScreen(),
              ),
            );
          }
        },
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
