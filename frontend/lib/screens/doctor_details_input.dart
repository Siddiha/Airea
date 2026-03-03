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

    if (fullName.isEmpty ||
        mobileNumber.isEmpty ||
        specializations.isEmpty ||
        medicalLicense.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

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
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
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
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: 'Enter your mobile number',
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
                decoration: InputDecoration(
                  labelText: 'Specializations',
                  hintText: 'e.g., Cardiology, Pulmonology',
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
                decoration: InputDecoration(
                  labelText: 'Medical License Number',
                  hintText: 'Enter your medical license number',
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Finish',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
