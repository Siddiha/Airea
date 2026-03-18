import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../widgets/bottom_nav_bar.dart';

class PatientNotifications extends StatelessWidget {
  final List<PatientNotification> alerts;

  const PatientNotifications({super.key, this.alerts = const []});

  @override
  Widget build(BuildContext context) {
    final List<PatientNotification> notifications = alerts;

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
                child: notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: notifications.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
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
      bottomNavigationBar: const PatientBottomNav(currentIndex: 0),
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

}