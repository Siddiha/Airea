import 'package:flutter/material.dart';
import '../models/patient_contact.dart';
import '../models/registration_data.dart';
import 'patient_upload_past_medical.dart';

class ContactInputScreen extends StatefulWidget {
  final RegistrationData? registrationData;
  final PatientContact? existingContact;

  const ContactInputScreen({
    super.key,
    this.registrationData,
    this.existingContact,
  });

  @override
  State<ContactInputScreen> createState() => _ContactInputScreenState();
}

class _ContactInputScreenState extends State<ContactInputScreen> {
  late TextEditingController _relationController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers if existing data is passed, otherwise empty
    _relationController =
        TextEditingController(text: widget.existingContact?.relationship ?? "");
    _phoneController =
        TextEditingController(text: widget.existingContact?.contactNumber ?? "");
  }

  @override
  void dispose() {
    _relationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final relationship = _relationController.text.trim();
    final contactNumber = _phoneController.text.trim();

    if (relationship.isEmpty || contactNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final contact = PatientContact(
      relationship: relationship,
      contactNumber: contactNumber,
    );

    // Update registration data with emergency contact
    final updatedData = widget.registrationData!.copyWith(
      emergencyContact: contact,
    );

    // Navigate to upload medical reports page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadReportsScreen(registrationData: updatedData),
      ),
    );
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
                "Enter Emergency contact info", // Use the dynamic title here
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
                    onPressed: _handleContinue,
                    child: const Text("Continue", style: TextStyle(color: Colors.white, fontSize: 18)),
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