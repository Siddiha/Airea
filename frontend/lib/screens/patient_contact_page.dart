import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/patient_contact.dart';
import '../models/registration_data.dart';
import '../services/profile_service.dart';
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
  String? _relationError;
  String? _phoneError;

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

  Future<void> _handleContinue() async {
    final relationship = _relationController.text.trim();
    final contactNumber = _phoneController.text.trim();
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

    if (contactNumber.isEmpty) {
      setState(() => _phoneError = 'Contact number is required');
      hasError = true;
    } else if (!phoneRegex.hasMatch(contactNumber)) {
      setState(() => _phoneError = 'Enter a valid phone number (e.g. 07XXXXXXXX)');
      hasError = true;
    }

    if (hasError) return;

    final contact = PatientContact(
      relationship: relationship,
      contactNumber: contactNumber,
    );

    // Save locally for later access from profile screen
    await ProfileService.saveEmergencyContact(contact);

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
              _customTextField(_relationController, errorText: _relationError, onChanged: (_) => setState(() => _relationError = null)),
              const SizedBox(height: 30),
              const Text("Their contact Number", textAlign: TextAlign.center),
              const SizedBox(height: 10),
              _customTextField(_phoneController, isNumber: true, errorText: _phoneError, onChanged: (_) => setState(() => _phoneError = null)),
              const SizedBox(height: 50),
              Center(
                child: SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    style: AppTheme.primaryButton(),
                    onPressed: _handleContinue,
                    child: const Text('Continue'),
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
        fillColor: AppTheme.inputFillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        errorText: errorText,
      ),
    );
  }
}