import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/doctor_registration_data.dart';
import 'doctor_account_created.dart';

class DoctorDetailsInput extends StatefulWidget {
  final DoctorRegistrationData registrationData;

  const DoctorDetailsInput({
    super.key,
    required this.registrationData,
  });

  @override
  State<DoctorDetailsInput> createState() => _DoctorDetailsInputState();
}

class _DoctorDetailsInputState extends State<DoctorDetailsInput> {
  late TextEditingController _fullNameController;
  late TextEditingController _mobileNumberController;
  late TextEditingController _specializationsController;
  late TextEditingController _medicalLicenseController;

  String? _fullNameError;
  String? _mobileNumberError;
  String? _specializationsError;
  String? _medicalLicenseError;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
        text: widget.registrationData.fullName ?? '');
    _mobileNumberController = TextEditingController(
        text: widget.registrationData.mobileNumber ?? '');
    _specializationsController = TextEditingController(
        text: widget.registrationData.specializations ?? '');
    _medicalLicenseController = TextEditingController(
        text: widget.registrationData.medicalLicenseNumber ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileNumberController.dispose();
    _specializationsController.dispose();
    _medicalLicenseController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final fullName = _fullNameController.text.trim();
    final mobileNumber = _mobileNumberController.text.trim();
    final specializations = _specializationsController.text.trim();
    final medicalLicense = _medicalLicenseController.text.trim();

    setState(() {
      _fullNameError = null;
      _mobileNumberError = null;
      _specializationsError = null;
      _medicalLicenseError = null;
    });

    bool hasError = false;

    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (fullName.isEmpty) {
      setState(() => _fullNameError = 'Full Name is required');
      hasError = true;
    } else if (!nameRegex.hasMatch(fullName)) {
      setState(() => _fullNameError = 'Name should only contain letters');
      hasError = true;
    }

    final sriLankanPhoneRegex = RegExp(r'^(?:\+94|0)?7\d{8}$');
    if (mobileNumber.isEmpty) {
      setState(() => _mobileNumberError = 'Mobile Number is required');
      hasError = true;
    } else if (!sriLankanPhoneRegex.hasMatch(mobileNumber)) {
      setState(() => _mobileNumberError = 'Please enter a valid Sri Lankan structure (+947..., 07...)');
      hasError = true;
    }

    if (specializations.isEmpty) {
      setState(() => _specializationsError = 'Specializations are required');
      hasError = true;
    }

    if (medicalLicense.isEmpty) {
      setState(() => _medicalLicenseError = 'Medical License Number is required');
      hasError = true;
    }

    if (hasError) return;

    // Update registration data with doctor information
    final updatedData = widget.registrationData.copyWith(
      fullName: fullName,
      mobileNumber: mobileNumber,
      specializations: specializations,
      medicalLicenseNumber: medicalLicense,
    );

    // Navigate to account created screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorAccountCreated(registrationData: updatedData),
      ),
    );
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Professional Information',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Please help us to know more about you',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We need your professional details',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),

              // Full Name
              TextField(
                controller: _fullNameController,
                onChanged: (_) => setState(() => _fullNameError = null),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  errorText: _fullNameError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              // Mobile Number
              TextField(
                controller: _mobileNumberController,
                onChanged: (_) => setState(() => _mobileNumberError = null),
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: 'Enter your mobile number',
                  errorText: _mobileNumberError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Specializations
              TextField(
                controller: _specializationsController,
                onChanged: (_) => setState(() => _specializationsError = null),
                decoration: InputDecoration(
                  labelText: 'Specializations',
                  hintText: 'e.g., Cardiology, Pulmonology',
                  errorText: _specializationsError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.medical_services_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Medical License Number
              TextField(
                controller: _medicalLicenseController,
                onChanged: (_) => setState(() => _medicalLicenseError = null),
                decoration: InputDecoration(
                  labelText: 'Medical License Number',
                  hintText: 'Enter your medical license number',
                  errorText: _medicalLicenseError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.card_membership_outlined),
                ),
              ),
              const SizedBox(height: 32),

              // Finish Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: AppTheme.primaryButton(),
                  child: const Text('Finish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
