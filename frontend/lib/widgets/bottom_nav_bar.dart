import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/patient_homeScreen.dart';
import '../screens/patient_device_dashboard.dart';
import '../screens/patient_connect_device_option.dart';
import '../screens/patient_summary_overview.dart';

/// Standard bottom navigation bar for all patient screens.
///
/// [currentIndex]: 0 = Home, 1 = Device, 2 = Trends & summary
class PatientBottomNav extends StatelessWidget {
  final int currentIndex;

  const PatientBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
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
            isSelected: currentIndex == 0,
            onTap: () {
              if (currentIndex != 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PatientHomeScreen()),
                );
              }
            },
          ),
          _buildNavItem(
            icon: Icons.sensors,
            label: "Device",
            isSelected: currentIndex == 1,
            onTap: () {
              if (currentIndex != 1) {
                _navigateToDevice(context);
              }
            },
          ),
          _buildNavItem(
            icon: Icons.menu_book,
            label: "Trends &\nsummary",
            isSelected: currentIndex == 2,
            onTap: () {
              if (currentIndex != 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PatientSummaryOverview()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToDevice(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final linkedId = prefs.getString('linked_device_id');
    final hasDevice = linkedId != null && linkedId.isNotEmpty;
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => hasDevice
              ? const PatientDeviceDashboard()
              : const PatientConnectDeviceOption(),
        ),
      );
    }
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
