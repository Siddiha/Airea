import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'patient_notifications.dart';
import 'patient_profile_frame.dart';
import 'patient_connect_device_option.dart';
import 'patient_device_dashboard.dart';
import 'cough_analyzer_screen.dart';
import 'doctor_details.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../services/doctor_patient_service.dart';
import '../services/profile_service.dart';
import '../models/device_model.dart';
import 'patient_contact_doctor.dart';
import '../widgets/bottom_nav_bar.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final ApiService _apiService = ApiService();
  static const Duration _vitalsCacheTtl = Duration(hours: 1);
  String? _deviceId; // null until patient links a real device

  // Live Database Variables
  double temperature = 0.0;
  String temperatureStatus = "No device connected";

  int heartRate = 0;
  String heartRateStatus = "No device connected";
  bool leadsAreOff = false;

  double respiratoryRate = 0.0;
  String respiratoryRateStatus = "No device connected";
  bool rrEstimated = false;

  int coughCount = 0;
  String coughStatus = "No device connected";

  List<PatientNotification> _alerts = [];
  Timer? _refreshTimer;
  Map<String, dynamic>? _connectedDoctor;
  String _userName = 'user';

  @override
  void initState() {
    super.initState();
    _initDeviceAndLoad();
  }

  String _cacheKey(String suffix) {
    final id = _deviceId ?? 'unknown';
    return 'patient_home_vitals_${id}_$suffix';
  }

  void _applyVitalsToState({
    required double temp,
    required int bpm,
    required bool leadsOff,
    required double rr,
    required bool rrEstimatedValue,
  }) {
    temperature = temp;
    heartRate = bpm;
    leadsAreOff = leadsOff;
    respiratoryRate = rr;
    rrEstimated = rrEstimatedValue;

    temperatureStatus = _getTemperatureStatus(temperature);
    heartRateStatus =
        leadsAreOff ? "Leads Disconnected" : _getHeartRateStatus(heartRate);
    respiratoryRateStatus = leadsAreOff
        ? "Leads Disconnected"
        : _getRespiratoryRateStatus(respiratoryRate);
  }

  Future<void> _saveVitalsCache({
    required int bpm,
    required double rr,
    required bool leadsOff,
    required bool rrEstimatedValue,
  }) async {
    if (_deviceId == null || _deviceId!.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cacheKey('bpm'), bpm);
    await prefs.setDouble(_cacheKey('rr'), rr);
    await prefs.setBool(_cacheKey('leadsOff'), leadsOff);
    await prefs.setBool(_cacheKey('rrEstimated'), rrEstimatedValue);
    await prefs.setInt(
        _cacheKey('savedAtMs'), DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> _loadVitalsFromCacheIfFresh() async {
    if (_deviceId == null || _deviceId!.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final savedAtMs = prefs.getInt(_cacheKey('savedAtMs'));
    if (savedAtMs == null) return false;

    final age = DateTime.now().millisecondsSinceEpoch - savedAtMs;
    if (age > _vitalsCacheTtl.inMilliseconds) return false;

    final cachedBpm = prefs.getInt(_cacheKey('bpm'));
    final cachedRr = prefs.getDouble(_cacheKey('rr'));
    final cachedLeadsOff = prefs.getBool(_cacheKey('leadsOff'));
    final cachedRrEstimated = prefs.getBool(_cacheKey('rrEstimated')) ?? false;

    if (cachedBpm == null || cachedRr == null || cachedLeadsOff == null) {
      return false;
    }

    if (!mounted) return false;
    setState(() {
      _applyVitalsToState(
        temp: temperature,
        bpm: cachedBpm,
        leadsOff: cachedLeadsOff,
        rr: cachedRr,
        rrEstimatedValue: cachedRrEstimated,
      );
    });
    return true;
  }

  /// Load the patient's linked device ID, then start fetching data only if linked.
  Future<void> _initDeviceAndLoad() async {
    // Cancel any existing timer before potentially creating a new one
    _refreshTimer?.cancel();
    _refreshTimer = null;

    final prefs = await SharedPreferences.getInstance();
    final linkedId = await ProfileService.getLinkedDevice();
    final hasLinkedDevice = linkedId != null && linkedId.isNotEmpty;
    String? savedName = prefs.getString('user_full_name');

    // If name not cached locally, fetch from Supabase patients table
    if (savedName == null || savedName.isEmpty) {
      try {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser?.email != null) {
          final row = await Supabase.instance.client
              .from('patients')
              .select('full_name')
              .eq('email', currentUser!.email!)
              .maybeSingle();
          if (row != null &&
              row['full_name'] != null &&
              (row['full_name'] as String).isNotEmpty) {
            savedName = row['full_name'] as String;
            await prefs.setString('user_full_name', savedName);
          }
        }
      } catch (_) {
        // Non-fatal – name stays as default 'user'
      }
    }

    if (mounted) {
      setState(() {
        _deviceId = hasLinkedDevice ? linkedId : null;
        if (savedName != null && savedName.isNotEmpty) {
          _userName = savedName;
        }
        // Reset vitals display when no device is linked, but keep _alerts intact
        if (!hasLinkedDevice) {
          temperature = 0.0;
          temperatureStatus = "No device connected";
          heartRate = 0;
          heartRateStatus = "No device connected";
          leadsAreOff = false;
          respiratoryRate = 0.0;
          respiratoryRateStatus = "No device connected";
          rrEstimated = false;
          coughCount = 0;
          coughStatus = "No device connected";
        }
      });
    }

    // Only fetch device data if a device is actually linked
    if (_deviceId != null && _deviceId!.isNotEmpty) {
      await _loadVitalsFromCacheIfFresh();
      _loadCoughData();
      _loadVitalsData();
      _loadAlerts();

      // Refresh every 10 seconds
      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _loadCoughData();
        _loadVitalsData();
        _loadAlerts();
      });
    }

    _loadConnectedDoctor();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // --- DATA FETCHING ---

  Future<void> _loadCoughData() async {
    if (_deviceId == null || _deviceId!.isEmpty) return;
    try {
      final stats = await _apiService.getTodayStatistics(_deviceId!);
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
    if (_deviceId == null || _deviceId!.isEmpty) return;
    try {
      final vitals = await _apiService.getLatestVitals(_deviceId!);
      if (mounted && vitals != null) {
        setState(() {
          _applyVitalsToState(
            temp: vitals.temp,
            bpm: vitals.bpm,
            leadsOff: vitals.leadsOff,
            rr: vitals.respiratoryRate,
            rrEstimatedValue: vitals.rrEstimated,
          );
        });

        await _saveVitalsCache(
          bpm: vitals.bpm,
          rr: vitals.respiratoryRate,
          leadsOff: vitals.leadsOff,
          rrEstimatedValue: vitals.rrEstimated,
        );
      } else {
        await _loadVitalsFromCacheIfFresh();
      }
    } catch (e) {
      print('Error loading vitals: $e');
      final loadedFromCache = await _loadVitalsFromCacheIfFresh();
      if (mounted && !loadedFromCache) {
        setState(() {
          temperatureStatus = "Offline";
          heartRateStatus = "Offline";
          respiratoryRateStatus = "Offline";
        });
      }
    }
  }

  bool _criticalBannerShown = false;

  Future<void> _loadAlerts() async {
    if (_deviceId == null || _deviceId!.isEmpty) return;
    try {
      final newAlerts = await _apiService.getFallAlerts(_deviceId!);
      if (mounted) {
        setState(() {
          // Merge new alerts with existing ones, avoiding duplicates
          final existingTitles =
              _alerts.map((a) => '${a.title}_${a.time}').toSet();
          for (final alert in newAlerts) {
            if (!existingTitles.contains('${alert.title}_${alert.time}')) {
              _alerts.add(alert);
            }
          }
        });
        // Pop up a banner the first time we detect a CRITICAL alert
        if (!_criticalBannerShown && _alerts.any((a) => a.isHighAlert)) {
          _criticalBannerShown = true;
          _showCriticalBanner(_alerts.firstWhere((a) => a.isHighAlert));
        }
      }
    } catch (e) {
      print('Error loading alerts: $e');
    }
  }

  Future<void> _loadConnectedDoctor() async {
    try {
      final doctors = await DoctorPatientService.getConnectedDoctors();
      if (mounted) {
        setState(() {
          _connectedDoctor = doctors.isNotEmpty ? doctors.first : null;
        });
      }
    } catch (e) {
      print('Error loading connected doctor: $e');
    }
  }

  OverlayEntry? _criticalOverlay;

  void _showCriticalBanner(PatientNotification alert) {
    _criticalOverlay?.remove();
    _criticalOverlay = OverlayEntry(
      builder: (_) => _CriticalAlertToast(
        alert: alert,
        onView: () {
          _criticalOverlay?.remove();
          _criticalOverlay = null;
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PatientNotifications(alerts: _alerts)));
        },
        onDismiss: () {
          _criticalOverlay?.remove();
          _criticalOverlay = null;
        },
      ),
    );
    Overlay.of(context).insert(_criticalOverlay!);
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

  String _getRespiratoryRateStatus(double rr) {
    if (rr == 0.0) return "No Data";
    if (rr < 12) return "Low (Bradypnea)";
    if (rr > 20) return "High (Tachypnea)";
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
                _buildRespiratoryRateCard(),
                const SizedBox(height: 12),
                _buildCoughCountCard(),
                const SizedBox(height: 12),
                _buildConnectionCard(
                  title: _deviceId != null && _deviceId!.isNotEmpty
                      ? "Device connected"
                      : "Connect with a\ndevice",
                  buttonLabel: _deviceId != null && _deviceId!.isNotEmpty
                      ? "View Device"
                      : "Connect",
                  onTap: () {
                    final destination =
                        _deviceId != null && _deviceId!.isNotEmpty
                            ? const PatientDeviceDashboard()
                            : const PatientConnectDeviceOption();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => destination),
                    ).then((_) => _initDeviceAndLoad());
                  },
                ),
                const SizedBox(height: 10),
                if (_connectedDoctor != null) ...[
                  _buildConnectedDoctorCard(),
                ] else ...[
                  _buildConnectionCard(
                    title: "Connect with a\ndoctor",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PatientContactDoctor()),
                      ).then((_) => _initDeviceAndLoad());
                    },
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const PatientBottomNav(currentIndex: 0),
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
        Expanded(
          child: Text("Hello $_userName !",
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PatientNotifications(alerts: _alerts))),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined,
                  color: Colors.black87, size: 26),
              if (_alerts.isNotEmpty)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _alerts.length > 99 ? '99+' : '${_alerts.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
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

  Widget _buildRespiratoryRateCard() {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Respiratory Rate",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                (respiratoryRate == 0.0 || leadsAreOff)
                    ? "--"
                    : "${respiratoryRate.toStringAsFixed(1)} br/min",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(respiratoryRateStatus)),
              ),
              const SizedBox(height: 2),
              Text(
                respiratoryRateStatus,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(respiratoryRateStatus)),
              ),
              if (!leadsAreOff && respiratoryRate > 0.0 && rrEstimated) ...[
                const SizedBox(height: 2),
                Text(
                  "Estimated",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
          Icon(Icons.air_rounded,
              size: 48,
              color: _getStatusColor(respiratoryRateStatus)
                  .withValues(alpha: 0.7)),
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
            onPressed: _deviceId != null && _deviceId!.isNotEmpty
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            CoughAnalyzerScreen(deviceId: _deviceId!)))
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
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
      {required String title,
      required VoidCallback onTap,
      String buttonLabel = "Connect"}) {
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
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              elevation: 0,
            ),
            child: Text(buttonLabel,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedDoctorCard() {
    final name = _connectedDoctor!['doctorName'] ?? 'Unknown';
    final specialization = _connectedDoctor!['specialization'] ?? '';
    final code = _connectedDoctor!['doctorCode'] ?? '';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorDetails(
              doctorName: name,
              phoneNumber: _connectedDoctor!['phoneNumber'] ?? '',
              specialization: specialization,
              hospital: _connectedDoctor!['hospital'] ?? '',
              doctorCode: code,
            ),
          ),
        ).then((_) => _initDeviceAndLoad());
      },
      child: Container(
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
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryTeal.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.medical_services_outlined,
                  color: AppTheme.primaryTeal, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Your Doctor",
                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                  if (specialization.isNotEmpty)
                    Text(specialization,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
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

// ── Bottom-right critical alert toast ────────────────────────────────────────
class _CriticalAlertToast extends StatefulWidget {
  final PatientNotification alert;
  final VoidCallback onView;
  final VoidCallback onDismiss;

  const _CriticalAlertToast({
    required this.alert,
    required this.onView,
    required this.onDismiss,
  });

  @override
  State<_CriticalAlertToast> createState() => _CriticalAlertToastState();
}

class _CriticalAlertToastState extends State<_CriticalAlertToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(begin: const Offset(1.2, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    // Auto-dismiss after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: Colors.red, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Critical Alert',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _dismiss,
                        child: Icon(Icons.close,
                            size: 16, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Alert message
                  Text(
                    widget.alert.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _dismiss,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Dismiss',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: widget.onView,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('View Alerts',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
