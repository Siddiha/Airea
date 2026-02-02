import 'package:flutter/material.dart';
import '../models/patient_medical_info.dart'; 
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
    // Initialize with existing data if available, converted to String
    _ageController = TextEditingController(text: widget.existingMedical?.age.toString() ?? "");
    _heightController = TextEditingController(text: widget.existingMedical?.height.toString() ?? "");
    _weightController = TextEditingController(text: widget.existingMedical?.weight.toString() ?? "");
    _genderController = TextEditingController(text: widget.existingMedical?.gender ?? "");
    _habitsController = TextEditingController(text: widget.existingMedical?.habbits ?? "");
    _workingEnvironmentController = TextEditingController(text: widget.existingMedical?.workingEnvironment ?? "");
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Edit medical details",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              
              // Input fields with labels as hint text inside the box
              _customTextField(_ageController, "Age", isNumber: true),
              const SizedBox(height: 15),
              _customTextField(_heightController, "Height", isNumber: true),
              const SizedBox(height: 15),
              _customTextField(_weightController, "Weight", isNumber: true),
              const SizedBox(height: 15),
              _customTextField(_genderController, "Gender"),
              const SizedBox(height: 15),
              _customTextField(_habitsController, "Do you smoke or use tobacco?", isDropdown: true),
              const SizedBox(height: 15),
              _customTextField(_workingEnvironmentController, "Working environment", isDropdown: true),
              
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
                    onPressed: () {
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

  Widget _customTextField(TextEditingController controller, String hint, {bool isNumber = false, bool isDropdown = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFD1D9E0), // Light greyish-blue from image
        //suffixIcon: isDropdown ? const Icon(Icons.arrow_drop_down, color: Colors.black54) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }
}