import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import 'patient_device_disconnected.dart';
import 'patient_device_manual.dart';
import 'patient_summary_overview.dart';
import 'patient_homeScreen.dart';


import '../models/device_model.dart'; 

class PatientDeviceDashboard extends StatefulWidget {
  const PatientDeviceDashboard({super.key});

  @override
  State<PatientDeviceDashboard> createState() => _PatientDeviceDashboardState();
}

class _PatientDeviceDashboardState extends State<PatientDeviceDashboard> {
  final DeviceController controller = DeviceController();
  String _deviceID = '---';
  int _batteryLevel = 70;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final linkedId = prefs.getString('linked_device_id');
    if (mounted && linkedId != null && linkedId.isNotEmpty) {
      setState(() {
        _deviceID = linkedId;
        _batteryLevel = controller.currentDevice?.batteryLevel ?? 70;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Device',
          style: TextStyle(
            color: Colors.black, 
            fontSize: 24,
            fontWeight: FontWeight.w600
          ),
        ),
        backgroundColor: const Color(0xFFF8FAFC), 
        elevation: 0,
        centerTitle: false, 
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0), 
          child: Column(
            children: [
              const SizedBox(height: 20),

              // 1. BATTERY STATUS CARD
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        "Device’s battery\npercentage",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          height: 1.2,
                        ),
                      ),
                    ),
                    // Battery Circle
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            // Dynamic Value 
                            value: _batteryLevel / 100, 
                            strokeWidth: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF5A9BD5), 
                            ),
                          ),
                          Center(
                            child: Text(
                              '$_batteryLevel%', 
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5A9BD5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 2. DISCONNECT BUTTON 
              SizedBox(
                width: 220, 
                height: 55,
                child: ElevatedButton(
                  onPressed: () => _showDisconnectConfirmation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FA095), 
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Disconnect',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 3. DEVICE ID CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "Device’s unique ID",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _deviceID, 
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. USER MANUAL BUTTON 
              SizedBox(
                width: 220,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PatientDeviceManual(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FA095),
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'User Manual',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
              ),

              const Spacer(), 

              // 5. FOOTER TEXT
              const Text(
                'If you have any issues related to\nthe device please contact\n+94 xxx xxxx',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNav(context),
    );
  }

  void _showDisconnectConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Disconnect Device',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to disconnect the device? '
          'You will stop receiving live vitals and alerts until a new device is connected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // close dialog

              controller.disconnectDevice();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('linked_device_id');

              if (context.mounted) {
                // Go back to home, clearing device screens from the stack
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Yes, Disconnect', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // BOTTOM NAVIGATION 
  Widget _buildCustomBottomNav(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home,
            label: "Home",
            isSelected: false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
              );
            },
          ),
          _buildNavItem(
            icon: Icons.sensors,
            label: "Device",
            isSelected: true,
            onTap: () {
              // Already on device page, do nothing
            },
          ),
          _buildNavItem(
            icon: Icons.menu_book,
            label: "Trends &\nsummary",
            isSelected: false,
            onTap: () {
              Navigator.pushReplacement(
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      ),
    );
  }
}