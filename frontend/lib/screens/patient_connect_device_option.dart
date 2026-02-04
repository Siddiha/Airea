import 'package:flutter/material.dart';
import '../config/app_theme.dart'; 
import 'patient_connect_device_code.dart';
import 'patient_homeScreen.dart';
import 'patient_summary_overview.dart';

class PatientConnectDeviceOption extends StatelessWidget {
  const PatientConnectDeviceOption({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2), 

              // 1. MAIN QUESTION TEXT
              const Text(
                'Do you want to pair\nwith the wearable\ndevice ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24, 
                  height: 1.3,
                  fontWeight: FontWeight.w600, 
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 50),

              // 2. "YES" BUTTON
              _buildOptionButton(
                context: context,
                label: "Yes",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PatientConnectDeviceCode(),
                    ),
                  );
                  print("Yes Pressed - Go to Code Screen");
                },
              ),

              const SizedBox(height: 20), // Spacing between buttons

              // 3. "NO" BUTTON
              _buildOptionButton(
                context: context,
                label: "No",
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNav(context),
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 3), 
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5F9EA0), 
          foregroundColor: Colors.white,
          elevation: 0, 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBottomNav(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Home Item
          _buildNavItem(
            icon: Icons.home,
            label: "Home",
            isSelected: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
              );
            }, 
          ),
          
          // Device Item 
          _buildNavItem(
            icon: Icons.sensors, 
            label: "Device",
            isSelected: true, 
            onTap: (){}
          ),

          // Trends Item
          _buildNavItem(
            icon: Icons.menu_book, 
            label: "Trends &\nsummary",
            isSelected: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PatientSummaryOverview()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color itemColor = isSelected ? Colors.black : Colors.grey.shade400;
    return GestureDetector(
    onTap: onTap, 
    behavior: HitTestBehavior.opaque, 
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 30,
          color: itemColor, 
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: itemColor,
            height: 1.1,
          ),
        ),
      ],
    ),
    );
}}



  