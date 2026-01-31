import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'patient_device_connected.dart';

class PatientConnectDeviceCode extends StatelessWidget {
  const PatientConnectDeviceCode({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height - 100, 
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // 1. Title Text
                const Text(
                  'Please enter unique\ncode ID provided for\nthe wearable device',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 30),

                // 2. Input Field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFC7D0D5), 
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: TextField(
                    textAlign: TextAlign.left,
                    decoration: const InputDecoration(
                      hintText: 'type',
                      hintStyle: TextStyle(color: Colors.black54, fontSize: 16),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 25, vertical: 14),
                    ),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),

                const SizedBox(height: 30),

                // 3. Confirm Button
                SizedBox(
                  width: 180, 
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PatientDeviceConnected(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F9EA0), 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                      shadowColor: Colors.grey.withOpacity(0.5),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // 4. Bottom Info Text
                const Text(
                  'Get unique code from the\nuser manual provided with\nthe wearable device',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 20),

                // 5. Guidance Button
                SizedBox(
                  width: 180,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      print("Guidance Clicked");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F9EA0), 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                      shadowColor: Colors.grey.withOpacity(0.5),
                    ),
                    child: const Text(
                      'Guidance',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNav(context),
    );
  }

  // Navigation Bar 
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
          _buildNavItem(icon: Icons.home, label: "Home", isSelected: false),
          _buildNavItem(icon: Icons.sensors, label: "Device", isSelected: true),
          _buildNavItem(icon: Icons.menu_book, label: "Trends &\nsummary", isSelected: false),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required bool isSelected}) {
    final Color itemColor = isSelected ? Colors.black : Colors.grey.shade400;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 30, color: itemColor),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: itemColor, height: 1.1),
        ),
      ],
    );
  }
}