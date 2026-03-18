import 'package:flutter/material.dart';
import 'guidance_to_connect_patient.dart';
import 'patient_connection_message.dart';
import '../services/doctor_patient_service.dart';

class ConnectWithPatient extends StatefulWidget {
  const ConnectWithPatient({super.key});

  @override
  State<ConnectWithPatient> createState() => _ConnectWithPatientState();
}

class _ConnectWithPatientState extends State<ConnectWithPatient> {
  // 1. Controller to capture the Patient ID from the text field
  final TextEditingController _idController = TextEditingController();
  bool _isLoading = false;
  String? _idError;

  Future<void> _handleConnect() async {
    final String patientCodeInput = _idController.text.trim();
    final codeRegex = RegExp(r'^[a-zA-Z0-9_-]+$');

    setState(() => _idError = null);

    if (patientCodeInput.isEmpty) {
      setState(() => _idError = 'Please enter a Patient Code');
      return;
    }

    if (!codeRegex.hasMatch(patientCodeInput)) {
      setState(() => _idError = 'Code can only contain letters, numbers, hyphens, and underscores');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final error = await DoctorPatientService.connectPatient(
        patientCode: patientCodeInput,
      );

      if (!mounted) return;

      if (error == null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PatientConnectionMessage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Could not connect. Is the server running?")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF0),
      body: SafeArea(
        child: Stack(
          children: [
        
            // Main Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Please enter patient’s\nid",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      ),
                  ),

                  const SizedBox(height: 20),

                  // Text Field
                 SizedBox(
                        width: 250,
                          child: TextField(
                            controller: _idController,
                            onChanged: (_) => setState(() => _idError = null),
                         decoration: InputDecoration(
                             hintText: "type",
                              filled: true,
                          fillColor: Colors.grey[300],
                         contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                            vertical: 14,
                         ),
                           border: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(25), 
                            borderSide: BorderSide.none,
                      ),
                      errorText: _idError,
                        ),
                      ),
                   ),

                  const SizedBox(height: 20),

                  // Confirm Button
                  SizedBox(
                    width: 150,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5DA092),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: _handleConnect, // 5. Trigger the API call
                      child: const Text("Confirm"),
                    ),
                  ),

                  const SizedBox(height: 60),

                  const Text(
                    "Please contact with\ndoctor to get his/her id",
                    textAlign: TextAlign.center,
                     style: TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.bold,
                   ),
                  ),

                  const SizedBox(height: 20),

                  // Guidance Button
                  SizedBox(
                    width: 280,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5DA092),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 5,
                      ),
                      onPressed: () {
                        Navigator.push(
                               context,
                           MaterialPageRoute(
                        builder: (context) => const GuidanceToConnectPatient(),
                       ),
                        );
                      },
                      child: const Text(
                        "Guidance to connect \n with patient",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                               fontSize: 14,   
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Home
            const Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Icon(Icons.home, size: 28),
                  Text("Home"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}