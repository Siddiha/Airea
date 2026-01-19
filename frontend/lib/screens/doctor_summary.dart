import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/custom_button.dart';
import 'doctor_daily_summary.dart';
import 'doctor_weekly_summary.dart';
import 'doctor_select_report.dart';
import 'doctor_allergic_conditions.dart';
import 'doctor_home_page.dart';

class DoctorSummary extends StatefulWidget {
  const DoctorSummary({Key? key}) : super(key: key);

  @override
  State<DoctorSummary> createState() => _DoctorSummaryState();
}

class _DoctorSummaryState extends State<DoctorSummary> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DoctorHomePage()),
        );
        break;
      case 1:
        // Already on Summary
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Summary',
          style: TextStyle(
            color: AppTheme.darkBlue,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomButton(
                text: 'Daily summary',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DoctorDailySummary()),
                  );
                },
                isPrimary: true,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Weekly summary',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DoctorWeeklySummary()),
                  );
                },
                isPrimary: true,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'View past medical reports',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DoctorSelectReport()),
                  );
                },
                isPrimary: true,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Allergic conditions',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DoctorAllergicConditions()),
                  );
                },
                isPrimary: true,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: 'Trends & summary',
          ),
        ],
      ),
    );
  }
}
