import 'package:flutter/material.dart';
import '../models/patient_contact.dart';
import '../services/profile_service.dart';
import 'patient_profile_frame.dart';

class EditEmergencyInfo extends StatefulWidget {
  //final String title; 
  final PatientContact? existingContact; 

  const EditEmergencyInfo({
    super.key, 
    //required this.title, 
    this.existingContact,
  });

  @override
  State<EditEmergencyInfo> createState() => _ContactInputScreenState();
}

class _ContactInputScreenState extends State<EditEmergencyInfo> {
  late TextEditingController _relationController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers if existing data is passed, otherwise try loading from storage
    _relationController = TextEditingController();
    _phoneController = TextEditingController();
    if (widget.existingContact != null) {
      _relationController.text = widget.existingContact!.relationship;
      _phoneController.text = widget.existingContact!.contactNumber;
    } else {
      ProfileService.loadEmergencyContact().then((c) {
        if (c != null) {
          _relationController.text = c.relationship;
          _phoneController.text = c.contactNumber;
        }
      });
    }
  }

  @override
  void dispose() {
    _relationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Edit emergency contact info", // Use the dynamic title here
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 60),
              const Text("What is their relationship to you?", textAlign: TextAlign.center),
              const SizedBox(height: 10),
              _customTextField(_relationController),
              const SizedBox(height: 30),
              const Text("Their contact Number", textAlign: TextAlign.center),
              const SizedBox(height: 10),
              _customTextField(_phoneController, isNumber: true),
              const SizedBox(height: 50),
              Center(
                child: SizedBox(
                  width: 200,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF132348),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () async {
                      if (_relationController.text.isNotEmpty) {
                        final entry = PatientContact(
                          relationship: _relationController.text,
                          contactNumber: _phoneController.text,
                        );
                        await ProfileService.saveEmergencyContact(entry);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PatientProfileFrame(),
                          ),
                        );
                      }
                    },
                    child: const Text("Confirm", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customTextField(TextEditingController controller, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFD9E2E8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }
}