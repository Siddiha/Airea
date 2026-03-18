import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'patient_pending_message.dart';
import 'patient_guidance_to_connect_with_doctor.dart';
import 'patient_homeScreen.dart';
import '../config/api_config.dart';

class PatientConnectWithDoctor extends StatefulWidget {
  const PatientConnectWithDoctor({super.key});

  @override
  State<PatientConnectWithDoctor> createState() =>
      _PatientConnectWithDoctorState();
}

class _PatientConnectWithDoctorState extends State<PatientConnectWithDoctor> {
  int _selectedIndex = 0;

  // 1. Add the controller to capture the Doctor's ID
  final TextEditingController _idController = TextEditingController();
  String? _idError;

  Future<void> _handleConnect() async {
    final String doctorCodeInput = _idController.text.trim();

    // Get the actual patient code from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? currentPatientCode = prefs.getString('patient_code');

    if (currentPatientCode == null || currentPatientCode.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Patient code not found. Please check your profile first.")),
      );
      return;
    }

    if (doctorCodeInput.isEmpty) {
      setState(() => _idError = 'Please enter a Doctor Code');
      return;
    }

    final codeRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!codeRegex.hasMatch(doctorCodeInput)) {
      setState(() => _idError = 'Doctor code can only contain letters, numbers, hyphens, and underscores');
      return;
    }

    setState(() => _idError = null);

    final url = Uri.parse('${ApiConfig.baseUrl}/connections/add-by-code');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "doctorCode": doctorCodeInput, 
          "patientCode": currentPatientCode, 
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PatientPendingMessage()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.body)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Could not connect. Is the server running?")),
      );
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  void dispose() {
    _idController.dispose(); // Always dispose controllers to save memory
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Please enter doctor’s id",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // 3. Linked the controller to the TextField
              SizedBox(
                width: 350,
                child: TextField(
                  controller: _idController, 
                  onChanged: (_) => setState(() => _idError = null),
                  decoration: InputDecoration(
                    hintText: 'type',
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    errorText: _idError,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4. Confirm Button now calls _handleConnect
              SizedBox(
                width: 220,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: _handleConnect, 
                  child: const Text("Confirm"),
                ),
              ),

              const SizedBox(height: 100),
              const Text(
                "Please contact with doctor to get his/her id",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: 260,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientGuidanceToConnectWithDoctor(),
                      ),
                    );
                  },
                  child: const Text(
                    "Guidance to connect with doctor",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.wifi), label: 'Device'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Trends & summary'),
        ],
      ),
    );
  }
}