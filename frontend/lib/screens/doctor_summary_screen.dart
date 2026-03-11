import 'package:flutter/material.dart';
import 'doctor_daily_records_calendar.dart';
import 'doctor_weekly_records_calendar.dart';
import 'doctor_select_patient_report.dart';
import 'doctor_allergic_conditions_screen.dart';
import '../models/doctor_patient_connection.dart';

class DoctorSummaryScreen extends StatelessWidget {
  final DoctorPatientConnection? patient;

  const DoctorSummaryScreen({
    super.key,
    this.patient,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header with Patient Name ---
              if (patient != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF66A399),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Viewing Summary for:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patient!.patientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${patient!.patientId}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              if (patient != null) const SizedBox(height: 24),
              const Text(
                'Summary',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 40),

              Column(
                children: [
                  _buildSummaryButton(
                    label: "Daily summary",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DoctorDailyRecordsCalendar())
                      );
                      // Navigate to Daily Summary Screen
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  _buildSummaryButton(
                    label: "Weekly summary",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DoctorWeeklyRecordsCalendar()
                        ),
                      );
                      // Navigate to Weekly Summary Screen
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildSummaryButton(
                    label: "View past medical reports",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DoctorSelectPatientReport(),
                          ),
                        );
                      // Navigate to Reports Screen
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildSummaryButton(
                    label: "Allergic conditions",
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => const DoctorAllergicConditionsScreen(),
                          ),
                        );
                      // Navigate to Allergies Screen
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // --- Bottom Navigation Bar  ---
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 1. Home Button
            _buildNavItem(
              icon: Icons.home_filled,
              label: "Home",
              isSelected: false,
              onTap: () {
                Navigator.pop(context);
              },
            ),

            // 2. Trends & Summary Button (Active)
            _buildNavItem(
              icon: Icons.menu_book_outlined, 
              label: "Trends &\nsummary",
              isSelected: true, // This is the current screen
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildSummaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, 
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF5E9E94), 
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), 
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.black : Colors.grey,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.black : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
// --- TEMPORARY MAIN FUNCTION FOR TESTING ---
void main() {
  runApp(const MaterialApp(
    home: DoctorSummaryScreen(), 
    debugShowCheckedModeBanner: false,
  ));
}