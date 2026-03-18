import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import 'patient_device_connected.dart';
import 'patient_device_guidance.dart';
import '../models/device_model.dart';
import 'patient_homeScreen.dart';
import 'patient_summary_overview.dart';


class PatientConnectDeviceCode extends StatefulWidget {
  const PatientConnectDeviceCode({super.key});

  @override
  State<PatientConnectDeviceCode> createState() => _PatientConnectDeviceCodeState();
}

class _PatientConnectDeviceCodeState extends State<PatientConnectDeviceCode> {
  final TextEditingController _codeController = TextEditingController();
  final DeviceController _deviceLogic = DeviceController();

  @override
  void dispose() {
    _codeController.dispose(); 
    super.dispose();
  }

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
                    controller: _codeController, 
                    textAlign: TextAlign.left,
                    keyboardType: TextInputType.number, 
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
                    onPressed: () async {
                      // Get the text from the box
                      String input = _codeController.text.trim();
                      
                      // Ask Controller to validate
                      bool isSuccess = _deviceLogic.pairDevice(input);

                      if (isSuccess) {
                        // Save the device ID so the home screen uses it
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('linked_device_id', input);

                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PatientDeviceConnected(),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Invalid Code! Please try again."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PatientDeviceGuidance(),
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
          _buildNavItem(icon: Icons.home, label: "Home", isSelected: false, onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
              );},),
          _buildNavItem(icon: Icons.sensors, label: "Device", isSelected: true, onTap: () {
            // Already on device page, do nothing
          }),
          _buildNavItem(icon: Icons.menu_book, label: "Trends &\nsummary", isSelected: false, onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => PatientSummaryOverview()),
              );
            },),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required bool isSelected, required VoidCallback onTap,}) {
    final Color itemColor = isSelected ? Colors.black : Colors.grey.shade400;
    return GestureDetector(
    onTap: onTap, // <--- Connects the tap to the action
    behavior: HitTestBehavior.opaque, // Ensures the whole area is clickable
    child: Column(
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
    ),
    );
  }
}