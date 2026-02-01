import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class PatientNotifications extends StatelessWidget {
  const PatientNotifications({super.key});

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

              // --- Notification List ---
              _buildSimpleNotificationItem(
                title: "High heart beat detected",
                time: "13:00",
              ),
              const SizedBox(height: 16),
              _buildSimpleNotificationItem(
                title: "Connected with doctor",
                time: "12:56",
              ),
              const SizedBox(height: 16),
              _buildSimpleNotificationItem(
                title: "Device connected",
                time: "12:48",
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
              onTap: () {}
            ),
            _buildNavItem(
              icon: Icons.menu_book_outlined, 
              label: "Trends &\nsummary", 
              isSelected: false, 
              onTap: () {}
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), 
        borderRadius: BorderRadius.circular(30), 
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),
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