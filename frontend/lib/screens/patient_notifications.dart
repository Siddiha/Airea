import 'package:flutter/material.dart';
import '../models/device_model.dart';
import 'patient_connect_device_option.dart';
import 'patient_summary_overview.dart';

class PatientNotifications extends StatelessWidget {
  final List<PatientNotification> alerts;

  const PatientNotifications({super.key, this.alerts = const []});

  @override
  Widget build(BuildContext context) {
    final List<PatientNotification> notifications =
        alerts.isNotEmpty ? alerts : DeviceController().fetchNotifications();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),

              // Use Expanded + ListView.builder
              Expanded(
                child: ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final note = notifications[index];
                    return _buildSimpleNotificationItem(
                      title: note.title,
                      time: note.time,
                      isHighAlert: note.isHighAlert,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      
      // --- Bottom Navigation Bar ---
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
            _buildNavItem(
              icon: Icons.home_filled, 
              label: "Home", 
              isSelected: true, 
              onTap: () {
                Navigator.pop(context); 
              }
            ),
            _buildNavItem(
              icon: Icons.sensors, 
              label: "Device", 
              isSelected: false, 
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatientConnectDeviceOption(), 
                  ),
                );
              }
            ),
            _buildNavItem(
              icon: Icons.menu_book_outlined, 
              label: "Trends &\nsummary", 
              isSelected: false, 
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientSummaryOverview(),
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  // Widget for the simple pill-shaped notification card
  Widget _buildSimpleNotificationItem({
    required String title,
    required String time,
    bool isHighAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isHighAlert ? const Color(0xFFFFEBEE) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(30),
        border: isHighAlert
            ? Border.all(color: Colors.red.shade200, width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isHighAlert) ...[
            const Icon(Icons.warning_amber_rounded,
                color: Colors.red, size: 16),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isHighAlert ? Colors.red.shade700 : Colors.black87,
                fontWeight:
                    isHighAlert ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // Widget for Bottom Navigation Items
  Widget _buildNavItem({
    required IconData icon, 
    required String label, 
    required bool isSelected, 
    required VoidCallback onTap
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