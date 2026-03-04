import 'package:flutter/material.dart';
import '../models/patient_medical_info.dart';
import '../services/profile_service.dart';
import 'patient_profile_frame.dart';

class EditMedicalInfo extends StatefulWidget {
  final PatientMedicalDetails? existingMedical;

  const EditMedicalInfo({
    super.key,
    this.existingMedical,
  });


  @override
  State<EditMedicalInfo> createState() => _MedicalInputScreenState();
}

class _MedicalInputScreenState extends State<EditMedicalInfo> {
  // Define controllers for all fields in PatientMedicalDetails
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _genderController;
  late TextEditingController _habitsController;
  late TextEditingController _workingEnvironmentController;

  @override
  void initState() {
    super.initState();
    // If caller provided data use it, otherwise try loading from storage
    if (widget.existingMedical != null) {
      _ageController = TextEditingController(text: widget.existingMedical!.age.toString());
      _heightController = TextEditingController(text: widget.existingMedical!.height.toString());
      _weightController = TextEditingController(text: widget.existingMedical!.weight.toString());
      _genderController = TextEditingController(text: widget.existingMedical!.gender);
      _habitsController = TextEditingController(text: widget.existingMedical!.habbits);
      _workingEnvironmentController = TextEditingController(text: widget.existingMedical!.workingEnvironment);
    } else {
      // async load, but controllers must exist synchronously so fill later
      _ageController = TextEditingController();
      _heightController = TextEditingController();
      _weightController = TextEditingController();
      _genderController = TextEditingController();
      _habitsController = TextEditingController();
      _workingEnvironmentController = TextEditingController();
      ProfileService.loadMedicalDetails().then((m) {
        if (m != null) {
          _ageController.text = m.age.toString();
          _heightController.text = m.height.toString();
          _weightController.text = m.weight.toString();
          _genderController.text = m.gender;
          _habitsController.text = m.habbits;
          _workingEnvironmentController.text = m.workingEnvironment;
        }
      });
    }
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _genderController.dispose();
    _habitsController.dispose();
    _workingEnvironmentController.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Medical Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Update your medical details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'These values were provided during account creation',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 30),
              
              // Input fields with the nicer style borrowed from patient_more_info.dart
              _customTextField(_ageController, "Age", isNumber: true, icon: Icons.cake),
              const SizedBox(height: 15),
              _customTextField(_heightController, "Height (cm)", isNumber: true, icon: Icons.height),
              const SizedBox(height: 15),
              _customTextField(_weightController, "Weight (kg)", isNumber: true, icon: Icons.monitor_weight),
              const SizedBox(height: 15),
              _customTextField(_genderController, "Gender", icon: Icons.transgender),
              const SizedBox(height: 15),
              _customTextField(_habitsController, "Do you smoke or use tobacco?", icon: Icons.smoking_rooms),
              const SizedBox(height: 15),
              _customTextField(_workingEnvironmentController, "Working environment", icon: Icons.work),
              
              const SizedBox(height: 40),
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
                      // Data validation and parsing
                      final age = int.tryParse(_ageController.text) ?? 0;
                      final height = int.tryParse(_heightController.text) ?? 0;
                      final weight = int.tryParse(_weightController.text) ?? 0;

                      if (age > 0) {
                        final entry = PatientMedicalDetails(
                          age: age,
                          height: height,
                          weight: weight,
                          gender: _genderController.text,
                          habbits: _habitsController.text,
                          workingEnvironment: _workingEnvironmentController.text,
                        );
                        // Persist the updated info locally so profile screen can show it later
                        await ProfileService.saveMedicalDetails(entry);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PatientProfileFrame(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid age')),
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

  Widget _customTextField(TextEditingController controller, String label,
      {bool isNumber = false, IconData? icon}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }
}