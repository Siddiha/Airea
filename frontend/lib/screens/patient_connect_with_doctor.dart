import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 
import 'package:flutter/foundation.dart';
import 'patient_pending_message.dart';
import 'patient_guidance_to_connect_with_doctor.dart';

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

  // 2. Add the function to talk to your Java Backend
  Future<void> _handleConnect() async {
    final String doctorCodeInput = _idController.text.trim(); // The patient types "D001"
    
    // Instead of the long UUID, we use the short code you added to Supabase
    const String currentPatientCode = "P001";

    if (doctorCodeInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a Doctor Code")),
      );
      return;
    }

    final String host = kIsWeb ? "localhost" : "10.0.2.2";
    
    // 1. Pointing to the NEW endpoint that handles the short-code-to-UUID translation
    final url = Uri.parse('http://$host:8080/api/connections/add-by-code');

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
        // Success: Navigate to the pending message screen
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PatientPendingMessage()),
        );
      } else {
        // Error: Show backend message (e.g., "Already linked")
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.body)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server Error: Is Spring Boot running?")),
      );
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                  decoration: InputDecoration(
                    hintText: 'type',
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
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