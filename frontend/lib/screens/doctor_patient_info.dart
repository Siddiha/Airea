import 'package:flutter/material.dart';
import 'doctor_home_screen.dart';
import 'doctor_summary_screen.dart';
import '../services/doctor_patient_service.dart';
import '../models/doctor_patient_connection.dart';

class DoctorPatientInfo extends StatefulWidget {
  const DoctorPatientInfo({super.key});

  @override
  State<DoctorPatientInfo> createState() => _DoctorPatientInfoState();
}

class _DoctorPatientInfoState extends State<DoctorPatientInfo> {
  List<DoctorPatientConnection> _patients = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await DoctorPatientService.getConnectedPatients();
      if (mounted) {
        setState(() {
          _patients = patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading patients: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Connected Patients",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                        ? Center(
                            child: Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        : _patients.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No Patients Connected',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Connect a patient to view their summary',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _patients.length,
                                itemBuilder: (context, index) {
                                  final patient = _patients[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DoctorSummaryScreen(
                                              patient: patient,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF66A399),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                  0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white30,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    patient.patientName,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'ID: ${patient.patientCode}',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.7),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              color: Colors.white
                                                  .withOpacity(0.6),
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home Button
            GestureDetector(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorHomeScreen(),
                  ),
                  (route) => false,
                );
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home, color: Colors.black87),
                  SizedBox(height: 4),
                  Text("Home", style: TextStyle(fontSize: 12)),
                ],
              ),
            ),

            // Trends & Summary Button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorSummaryScreen(),
                  ),
                );
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined, color: Colors.black54),
                  SizedBox(height: 4),
                  Text(
                    "Trends & Summary",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}