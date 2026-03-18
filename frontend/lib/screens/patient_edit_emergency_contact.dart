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
  String? _relationError;
  String? _phoneError;

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const PatientProfileFrame(),
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
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
              _customTextField(_relationController, errorText: _relationError, onChanged: (_) => setState(() => _relationError = null)),
              const SizedBox(height: 30),
              const Text("Their contact Number", textAlign: TextAlign.center),
              const SizedBox(height: 10),
              _customTextField(_phoneController, isNumber: true, errorText: _phoneError, onChanged: (_) => setState(() => _phoneError = null)),
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
                      final relationship = _relationController.text.trim();
                      final phone = _phoneController.text.trim();
                      final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
                      final phoneRegex = RegExp(r'^(?:\+94|0)?7\d{8}$');
                      bool hasError = false;

                      setState(() {
                        _relationError = null;
                        _phoneError = null;
                      });

                      if (relationship.isEmpty) {
                        setState(() => _relationError = 'Relationship is required');
                        hasError = true;
                      } else if (!nameRegex.hasMatch(relationship)) {
                        setState(() => _relationError = 'Only letters and spaces are allowed');
                        hasError = true;
                      }

                      if (phone.isEmpty) {
                        setState(() => _phoneError = 'Contact number is required');
                        hasError = true;
                      } else if (!phoneRegex.hasMatch(phone)) {
                        setState(() => _phoneError = 'Enter a valid phone number (e.g. 07XXXXXXXX)');
                        hasError = true;
                      }

                      if (hasError) return;

                      final entry = PatientContact(
                        relationship: relationship,
                        contactNumber: phone,
                      );
                      await ProfileService.saveEmergencyContact(entry);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PatientProfileFrame(),
                        ),
                      );
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

  Widget _customTextField(TextEditingController controller, {bool isNumber = false, String? errorText, ValueChanged<String>? onChanged}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFD9E2E8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        errorText: errorText,
      ),
    );
  }
}