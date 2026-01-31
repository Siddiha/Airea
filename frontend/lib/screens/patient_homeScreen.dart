import 'dart:async';
import 'package:flutter/material.dart';

//import 'patient_notifications.dart';
import 'patient_profile_frame.dart';
import 'patient_connect_device_option.dart';
//import 'patient_connect_doctor_option.dart';
//import 'patient_summary_page.dart';
import 'cough_analyzer_screen.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final ApiService _apiService = ApiService();
  final String _deviceId = ApiConfig.defaultDeviceId;

  int spo2 = 98;
  String spo2Status = "Normal";

  int heartRate = 72;
  String heartRateStatus = "Normal";

  double temperature = 34.0;
  String temperatureStatus = "Normal";

  int coughCount = 600;
  String coughStatus = "High";

  int _selectedIndex = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadCoughData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadCoughData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCoughData() async {
    try {
      final stats = await _apiService.getTodayStatistics(_deviceId);
      if (mounted) {
        setState(() {
          coughCount = stats.totalCoughs;
          coughStatus = _getCoughStatus(stats.totalCoughs);
        });
      }
    } catch (e) {
      print('Error loading cough data: $e');
      if (mounted) {
        setState(() {
          coughStatus = "No data";
        });
      }
    }
  }

  String _getCoughStatus(int count) {
    if (count == 0) return "No coughs";
    if (count < 10) return "Low";
    if (count < 30) return "Normal";
    if (count < 50) return "Moderate";
    return "High";
  }

  Color _getCoughStatusColor(String status) {
    switch (status) {
      case "No coughs":
      case "Low":
      case "Normal":
        return const Color(0xFF4CAF50);
      case "Moderate":
        return Colors.orange;
      case "High":
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 20),

                // Live vitals title
                const Text(
                  "Live vitals",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Vitals Grid - exactly like the design
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column - SpO2 and Temperature
                    Expanded(
                      child: Column(
                        children: [
                          _buildSpO2Card(),
                          const SizedBox(height: 10),
                          _buildTemperatureCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Right column - Heart Rate (taller)
                    Expanded(
                      child: _buildHeartRateCard(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Cough Count Card
                _buildCoughCountCard(),
                const SizedBox(height: 12),

                // Connect with device
                _buildConnectionCard(
                  title: "Connect with a\ndevice",
                  onTap: () {
                    print("Connect Device Clicked");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientConnectDeviceOption(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Connect with doctor
                _buildConnectionCard(
                  title: "Connect with a\ndoctor",
                  onTap: () {
                    print("Connect Doctor Clicked");
                    // TODO: Uncomment when PatientConnectDoctorOption is created
                    /*Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientConnectDoctorOption(),
                      ),
                    );*/
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Profile icon
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PatientProfileFrame()),
            );
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black87, width: 2),
            ),
            child: const Icon(
              Icons.person_outline,
              color: Colors.black87,
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Greeting
        const Text(
          "Hello user !",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        // Notification bell with red dot
        GestureDetector(
          onTap: () {
            print("Notifications Clicked");
            // TODO: Uncomment when PatientNotifications is created
            /*Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PatientNotifications()),
            );*/
          },
          child: Stack(
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Colors.black87,
                size: 26,
              ),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpO2Card() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // O2 Icon with bubble
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Text(
                    "O",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const Positioned(
                    right: -8,
                    bottom: 0,
                    child: Text(
                      "2",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    top: -4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.shade300,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Status and Value
          Text(
            spo2Status,
            style: const TextStyle(
              color: Color(0xFF4CAF50),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          Text(
            "$spo2%",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "SpO2",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thermometer Icon
          Icon(
            Icons.thermostat_outlined,
            size: 28,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 10),
          Text(
            temperatureStatus,
            style: const TextStyle(
              color: Color(0xFF4CAF50),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          Text(
            "${temperature.toStringAsFixed(0)}°C",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Temperature",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ECG Line Drawing
          SizedBox(
            height: 80,
            width: double.infinity,
            child: CustomPaint(
              painter: ECGLinePainter(),
              size: const Size(double.infinity, 80),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Heart Rate",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$heartRate BPM",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            heartRateStatus,
            style: const TextStyle(
              color: Color(0xFF4CAF50),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoughCountCard() {
    final statusColor = _getCoughStatusColor(coughStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Cough Count",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                coughCount.toString(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              Text(
                coughStatus,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CoughAnalyzerScreen(deviceId: _deviceId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DB6AC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              elevation: 0,
            ),
            child: const Text(
              "View Cough Trends",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard({
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 8,
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
              color: Color(0xFF4CAF50),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DB6AC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              elevation: 0,
            ),
            child: const Text(
              "Connect",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: "Home",
                isSelected: _selectedIndex == 0,
                onTap: () {
                  setState(() => _selectedIndex = 0);
                },
              ),
              _buildNavItem(
                icon: Icons.sensors,
                label: "Device",
                isSelected: _selectedIndex == 1,
                onTap: () {
                  print("Device Tab Clicked");
                  setState(() => _selectedIndex = 1);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PatientConnectDeviceOption(),
                    ),
                  );
                },
              ),
              _buildNavItem(
                icon: Icons.menu_book_outlined,
                label: "Trends &\nsummary",
                isSelected: _selectedIndex == 2,
                onTap: () {
                  print("Trends Tab Clicked");
                  setState(() => _selectedIndex = 2);
                  // TODO: Uncomment when PatientSummaryPage is created
                  /*Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PatientSummaryPage(),
                    ),
                  );*/
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black87 : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.black87 : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// Static ECG Line Painter - matches the design exactly
class ECGLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    // Start from left
    path.moveTo(0, centerY);

    // Flat line
    path.lineTo(width * 0.15, centerY);

    // Small P wave
    path.lineTo(width * 0.18, centerY - 5);
    path.lineTo(width * 0.22, centerY);

    // Flat
    path.lineTo(width * 0.28, centerY);

    // QRS Complex - the main spike
    path.lineTo(width * 0.30, centerY + 5); // Q dip
    path.lineTo(width * 0.35, centerY - 35); // R spike up
    path.lineTo(width * 0.40, centerY + 10); // S dip
    path.lineTo(width * 0.45, centerY); // back to baseline

    // Flat
    path.lineTo(width * 0.55, centerY);

    // T wave
    path.lineTo(width * 0.60, centerY - 10);
    path.lineTo(width * 0.68, centerY);

    // Flat to end
    path.lineTo(width, centerY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
