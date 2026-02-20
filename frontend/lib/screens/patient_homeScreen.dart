import 'dart:async';
import 'package:flutter/material.dart';

import 'patient_notifications.dart';
import 'patient_profile_frame.dart';
import 'patient_connect_device_option.dart';
import 'patient_summary_overview.dart';
import 'cough_analyzer_screen.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'patient_contact_doctor.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final ApiService _apiService = ApiService();
  final String _deviceId = ApiConfig.defaultDeviceId;

  // Live Database Variables
  double temperature = 0.0;
  String temperatureStatus = "Loading...";

  int heartRate = 0;
  String heartRateStatus = "Loading...";
  bool leadsAreOff = false;

  int coughCount = 0;
  String coughStatus = "Loading...";

  int _selectedIndex = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Fetch immediately on load
    _loadCoughData();
    _loadVitalsData();

    // Refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadCoughData();
      _loadVitalsData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // --- DATA FETCHING ---

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
      if (mounted) setState(() => coughStatus = "No data");
    }
  }

  Future<void> _loadVitalsData() async {
    try {
      final vitals = await _apiService.getLatestVitals(_deviceId);
      if (mounted && vitals != null) {
        setState(() {
          temperature = vitals.temp;
          heartRate = vitals.bpm;
          leadsAreOff = vitals.leadsOff;

          // Medical Logic for Statuses
          temperatureStatus = _getTemperatureStatus(temperature);
          heartRateStatus = leadsAreOff
              ? "Leads Disconnected"
              : _getHeartRateStatus(heartRate);
        });
      }
    } catch (e) {
      print('Error loading vitals: $e');
      if (mounted) {
        setState(() {
          temperatureStatus = "Offline";
          heartRateStatus = "Offline";
        });
      }
    }
  }

  // --- STATUS HELPERS ---

  String _getCoughStatus(int count) {
    if (count == 0) return "No coughs";
    if (count < 10) return "Low";
    if (count < 30) return "Normal";
    if (count < 50) return "Moderate";
    return "High";
  }

  String _getTemperatureStatus(double temp) {
    if (temp == 0.0) return "No Data";
    if (temp < 35.0) return "Low (Hypothermia)";
    if (temp > 37.5) return "High (Fever)";
    return "Normal";
  }

  String _getHeartRateStatus(int bpm) {
    if (bpm == 0) return "No Data";
    if (bpm < 60) return "Low (Bradycardia)";
    if (bpm > 100) return "High (Tachycardia)";
    return "Normal";
  }

  Color _getStatusColor(String status) {
    if (status.contains("Normal") || status == "No coughs" || status == "Low") {
      return const Color(0xFF4CAF50); // Green
    } else if (status.contains("Moderate") || status.contains("Leads")) {
      return Colors.orange; // Orange
    } else if (status.contains("High") || status.contains("Low (")) {
      return const Color(0xFFE53935); // Red
    }
    return Colors.grey;
  }

  // --- UI BUILDERS ---

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
                _buildHeader(),
                const SizedBox(height: 20),
                const Text(
                  "Live vitals",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTemperatureCard()),
                    const SizedBox(width: 10),
                    Expanded(child: _buildHeartRateCard()),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCoughCountCard(),
                const SizedBox(height: 12),
                _buildConnectionCard(
                  title: "Connect with a\ndevice",
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const PatientConnectDeviceOption()));
                  },
                ),
                const SizedBox(height: 10),
                _buildConnectionCard(
                  title: "Connect with a\ndoctor",
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PatientContactDoctor()));
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
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PatientProfileFrame())),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black87, width: 2)),
            child: const Icon(Icons.person_outline,
                color: Colors.black87, size: 26),
          ),
        ),
        const SizedBox(width: 12),
        const Text("Hello user !",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PatientNotifications())),
          child: Stack(
            children: [
              const Icon(Icons.notifications_outlined,
                  color: Colors.black87, size: 26),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle)),
              ),
            ],
          ),
        ),
      ],
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
              color: Colors.grey.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              height: 86,
              child: Icon(Icons.thermostat_outlined,
                  size: 50, color: Colors.grey.shade600)),
          const SizedBox(height: 10),
          Text("Temperature",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            temperature == 0.0 ? "--" : "${temperature.toStringAsFixed(1)}°C",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(temperatureStatus)),
          ),
          const SizedBox(height: 4),
          Text(
            temperatureStatus,
            style: TextStyle(
                color: _getStatusColor(temperatureStatus),
                fontWeight: FontWeight.w600,
                fontSize: 13),
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
              color: Colors.grey.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 80,
            width: double.infinity,
            child: CustomPaint(
                painter:
                    ECGLinePainter(isFlatline: leadsAreOff || heartRate == 0),
                size: const Size(double.infinity, 80)),
          ),
          const SizedBox(height: 8),
          Text("Heart Rate",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
          const SizedBox(height: 8),
          Text(
            (heartRate == 0 || leadsAreOff) ? "--" : "$heartRate BPM",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(heartRateStatus)),
          ),
          const SizedBox(height: 4),
          Text(
            heartRateStatus,
            style: TextStyle(
                color: _getStatusColor(heartRateStatus),
                fontWeight: FontWeight.w600,
                fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCoughCountCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Cough Count",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 2),
              Text(coughCount.toString(),
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(coughStatus))),
              Text(coughStatus,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(coughStatus))),
            ],
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CoughAnalyzerScreen(deviceId: _deviceId))),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DB6AC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              elevation: 0,
            ),
            child: const Text("View Cough Trends",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(
      {required String title, required VoidCallback onTap}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.3)),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DB6AC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              elevation: 0,
            ),
            child: const Text("Connect",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
              color: Colors.grey.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3))
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
                  onTap: () => setState(() => _selectedIndex = 0)),
              _buildNavItem(
                  icon: Icons.sensors,
                  label: "Device",
                  isSelected: _selectedIndex == 1,
                  onTap: () {
                    setState(() => _selectedIndex = 1);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const PatientConnectDeviceOption()));
                  }),
              _buildNavItem(
                  icon: Icons.menu_book_outlined,
                  label: "Trends &\nsummary",
                  isSelected: _selectedIndex == 2,
                  onTap: () {
                    setState(() => _selectedIndex = 2);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PatientSummaryOverview()));
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      {required IconData icon,
      required String label,
      required bool isSelected,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected ? Colors.black87 : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.black87 : Colors.grey,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// Updated ECG Painter to draw a flatline if leads are disconnected
class ECGLinePainter extends CustomPainter {
  final bool isFlatline;
  ECGLinePainter({this.isFlatline = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isFlatline ? Colors.red.shade400 : Colors.grey.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final centerY = size.height / 2;

    path.moveTo(0, centerY);

    if (isFlatline) {
      path.lineTo(size.width, centerY); // Draw a straight line
    } else {
      final width = size.width;
      path.lineTo(width * 0.15, centerY);
      path.lineTo(width * 0.18, centerY - 5);
      path.lineTo(width * 0.22, centerY);
      path.lineTo(width * 0.28, centerY);
      path.lineTo(width * 0.30, centerY + 5);
      path.lineTo(width * 0.35, centerY - 35);
      path.lineTo(width * 0.40, centerY + 10);
      path.lineTo(width * 0.45, centerY);
      path.lineTo(width * 0.55, centerY);
      path.lineTo(width * 0.60, centerY - 10);
      path.lineTo(width * 0.68, centerY);
      path.lineTo(width, centerY);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ECGLinePainter oldDelegate) =>
      oldDelegate.isFlatline != isFlatline;
}
