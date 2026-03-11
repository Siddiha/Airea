import 'package:flutter/material.dart';
import 'doctor_notification.dart';
import 'doctor_profile_frame.dart';
import 'doctor_patient_info.dart';
import 'doctor_connect_patient_screen.dart';
import '../services/doctor_patient_service.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _patientCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPatientCount();
  }

  Future<void> _loadPatientCount() async {
    final count = await DoctorPatientService.getConnectedPatientCount();
    if (mounted) {
      setState(() => _patientCount = count);
    }
  }

  Future<void> _handleConnectPatient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DoctorConnectPatientScreen(),
      ),
    );

    // Refresh patient count if a patient was successfully connected
    if (result == true) {
      _loadPatientCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 70,
        color: Colors.white,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, color: Colors.black87),
            SizedBox(height: 4),
            Text("Home", style: TextStyle(fontSize: 12)),
          ],
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Top Bar
              Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Profile Navigation
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorProfileFrame(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF66A399),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Hello user !",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notification Navigation
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorNotificationScreen(),
                        ),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
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
                          child: const Icon(
                            Icons.notifications_none,
                            size: 24,
                            color: Colors.black87,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Total Patients Card
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DoctorPatientInfo(),
                    ),
                  );
                },
                child: _buildCardWithValue(
                  "Total number of patients",
                  _patientCount.toString(),
                ),
              ),

              const SizedBox(height: 32),

              // Connect Patient Card
              GestureDetector(
                onTap: _handleConnectPatient,
                child: _buildCardWithValue(
                  "Connect to a patient",
                  "+",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card Widget
  Widget _buildCardWithValue(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF66A399),
            ),
          ),
        ],
      ),
    );
  }
}