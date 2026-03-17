import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/registration_data.dart';
import '../models/patient_medical_info.dart';
import 'patient_contact_page.dart';

class PatientMoreInfo extends StatefulWidget {
  final RegistrationData registrationData;

  const PatientMoreInfo({
    super.key,
    required this.registrationData,
  });

  @override
  State<PatientMoreInfo> createState() => _PatientMoreInfoState();
}

class _PatientMoreInfoState extends State<PatientMoreInfo> {
  late TextEditingController _fullNameController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late String _selectedGender;

  // extra medical inputs
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _habitsController;
  late TextEditingController _workingEnvironmentController;

  String? _fullNameError;
  String? _dobError;
  String? _addressError;
  String? _ageError;
  String? _heightError;
  String? _weightError;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.registrationData.fullName ?? '');
    _dobController = TextEditingController(text: widget.registrationData.dateOfBirth ?? '');
    _addressController = TextEditingController(text: widget.registrationData.address ?? '');
    _selectedGender = widget.registrationData.gender ?? 'Male';

    // prefill for new medical fields if present
    final med = widget.registrationData.medicalDetails;
    _ageController = TextEditingController(text: med?.age.toString() ?? '');
    _heightController = TextEditingController(text: med?.height.toString() ?? '');
    _weightController = TextEditingController(text: med?.weight.toString() ?? '');
    _habitsController = TextEditingController(text: med?.habbits ?? '');
    _workingEnvironmentController = TextEditingController(text: med?.workingEnvironment ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _habitsController.dispose();
    _workingEnvironmentController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final fullName = _fullNameController.text.trim();
    final dob = _dobController.text.trim();
    final address = _addressController.text.trim();
    final ageText = _ageController.text.trim();
    final heightText = _heightController.text.trim();
    final weightText = _weightController.text.trim();

    setState(() {
      _fullNameError = null;
      _dobError = null;
      _addressError = null;
      _ageError = null;
      _heightError = null;
      _weightError = null;
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

    if (dob.isEmpty) {
      setState(() => _dobError = 'Date of birth is required');
      hasError = true;
    }

    if (address.isEmpty) {
      setState(() => _addressError = 'Address is required');
      hasError = true;
    }

    final age = int.tryParse(ageText);
    if (ageText.isEmpty) {
      setState(() => _ageError = 'Age is required');
      hasError = true;
    } else if (age == null || age <= 0) {
      setState(() => _ageError = 'Please enter a valid age');
      hasError = true;
    }

    final height = int.tryParse(heightText);
    if (heightText.isNotEmpty && (height == null || height <= 0)) {
      setState(() => _heightError = 'Please enter a valid height');
      hasError = true;
    }

    final weight = int.tryParse(weightText);
    if (weightText.isNotEmpty && (weight == null || weight <= 0)) {
      setState(() => _weightError = 'Please enter a valid weight');
      hasError = true;
    }

    if (hasError) return;

    // Update registration data with personal information
    final PatientMedicalDetails medDetails = PatientMedicalDetails(
      age: int.tryParse(_ageController.text) ?? 0,
      height: int.tryParse(_heightController.text) ?? 0,
      weight: int.tryParse(_weightController.text) ?? 0,
      gender: _selectedGender,
      habbits: _habitsController.text,
      workingEnvironment: _workingEnvironmentController.text,
    );

    final updatedData = widget.registrationData.copyWith(
      fullName: fullName,
      dateOfBirth: dob,
      gender: _selectedGender,
      address: address,
      medicalDetails: medDetails,
    );

    // Navigate to contact page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactInputScreen(registrationData: updatedData),
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
          'Personal Information',
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
                'Tell us about yourself',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We need some basic information',
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

              // Date of Birth
              TextField(
                controller: _dobController,
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  hintText: 'DD/MM/YYYY',
                  errorText: _dobError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _dobError = null;
                      _dobController.text = '${date.day}/${date.month}/${date.year}';
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Gender
              const Text(
                'Gender',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Male'),
                      value: 'Male',
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Female'),
                      value: 'Female',
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Address
              TextField(
                controller: _addressController,
                onChanged: (_) => setState(() => _addressError = null),
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter your address',
                  errorText: _addressError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),
              // ── Medical details that were previously missing ──
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _ageError = null),
                decoration: InputDecoration(
                  labelText: 'Age',
                  hintText: 'Enter your age',
                  errorText: _ageError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _heightError = null),
                decoration: InputDecoration(
                  labelText: 'Height (cm)',
                  hintText: 'Enter your height',
                  errorText: _heightError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _weightError = null),
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: 'Enter your weight',
                  errorText: _weightError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _habitsController,
                decoration: InputDecoration(
                  labelText: 'Do you smoke or use tobacco?',
                  hintText: 'Yes / No / Prefer not to say',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _workingEnvironmentController,
                decoration: InputDecoration(
                  labelText: 'Working environment',
                  hintText: 'e.g. Office / Outdoors / Factory',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Continue Button
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
                    'Continue',
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
