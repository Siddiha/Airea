import 'package:flutter/material.dart';
import 'doctor_remove_patient_screen.dart';
import 'doctor_patient_removed_success_screen.dart'; 

class DoctorManagePatientsScreen extends StatefulWidget {
  const DoctorManagePatientsScreen({super.key});

  @override
  State<DoctorManagePatientsScreen> createState() => _DoctorManagePatientsScreenState();
}

class _DoctorManagePatientsScreenState extends State<DoctorManagePatientsScreen> {
  // Sample data simulating registered patients
  final List<String> _patients = [
    "Patient name",
    "John Doe", 
    "Sarah Smith"
  ];

  void _removePatient(int index) {
    setState(() {
      _patients.removeAt(index);
    });
  }

  Future<void> _confirmRemove(int index) async {
    // 1. Navigate to the confirmation screen (Yes/No)
    final bool? shouldRemove = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DoctorRemovePatientScreen()),
    );

    // 2. If user clicked "Yes"
    if (shouldRemove == true) {
      // Remove the patient
      _removePatient(index);

      // Show the Success Screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DoctorPatientRemovedSuccessScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // --- Title ---
              const SizedBox(height: 20),
              const Text(
                "Manage Registered\nPatient’s",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 40),

              // --- Patient List ---
              Expanded(
                child: _patients.isEmpty 
                  ? const Center(child: Text("No patients registered"))
                  : ListView.builder(
                      itemCount: _patients.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5F9EA0), 
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _patients[index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Remove Button
                              GestureDetector(
                                onTap: () => _confirmRemove(index), 
                                child: Container(
                                  height: 45,
                                  width: 45,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB71C1C), 
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                       BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  ),
                                  child: const Icon(Icons.remove, color: Colors.white, size: 28),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ),

              // --- Connect Button ---
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Connect Patient screen is under construction")),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECEF), 
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2E8B57), 
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.add, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Press to connect\nwith a patient",
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),

      // --- Bottom Nav ---
      bottomNavigationBar: SizedBox(
        height: 80,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.home, size: 36, color: Colors.black),
              Text("Home", style: TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- MAIN FUNCTION FOR TESTING ---
void main() {
  runApp(const MaterialApp(
    home: DoctorManagePatientsScreen(),
    debugShowCheckedModeBanner: false,
  ));
}