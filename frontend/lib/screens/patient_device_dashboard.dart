import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'patient_device_disconnected.dart';
import 'patient_device_manual.dart';
import 'patient_summary_overview.dart';
import 'patient_homeScreen.dart';
import 'patient_summary_overview.dart';
import 'patient_homeScreen.dart';

class PatientDeviceDashboard extends StatelessWidget {
  const PatientDeviceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

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
                            value: 0.7, // 70%
                            strokeWidth: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF5A9BD5), 
                            ),
                          ),
                          const Center(
                            child: Text(
                              '70%',
                              style: TextStyle(
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                         builder: (context) => const PatientDeviceDisconnected(),
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
                  children: const [
                    Text(
                      "Device’s unique ID",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'XXX XXX',
                      style: TextStyle(
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
              Container(
                 width: double.infinity,
                 height: 60,
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
                 child: TextButton(
                   onPressed: () {
                    Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (context) => const PatientDeviceManual(),
                       ),
                     );
                   },
                   style: TextButton.styleFrom(
                     foregroundColor: Colors.black,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                   ),
                   child: const Text(
                     'User Manual',
                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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

  // BOTTOM NAVIGATION 
  Widget _buildCustomBottomNav(BuildContext context) {
    return Container(
      height: 85,
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
              );
            },
          ),
          _buildNavItem(
            icon: Icons.sensors,
            label: "Device",
            isSelected: true,
            onTap: () {},
          ),
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