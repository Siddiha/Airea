import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:intl/intl.dart';
import '../models/cough_event.dart';
import '../models/cough_statistics.dart';
import '../services/api_service.dart';
import 'device_screen.dart';
// import 'patient_summary_page.dart';

class CoughAnalyzerScreen extends StatefulWidget {
  final String deviceId;

  const CoughAnalyzerScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<CoughAnalyzerScreen> createState() => _CoughAnalyzerScreenState();
}

class _CoughAnalyzerScreenState extends State<CoughAnalyzerScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String _errorMessage = '';
  bool _isGeneratingData = false;

  CoughStatistics? _hourlyStats;
  List<CoughEvent> _recentEvents = [];

  Timer? _pollingTimer;

  List<CoughEvent> _cleanRecentEvents(List<CoughEvent> events) {
    // 1. Convert to a mutable list so we can sort it
    final allEvents = events.toList();

    // 2. Sort so the NEWEST (2026 dates) are at the TOP
    allEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 3. Take the top 3 (or 5) to show on screen
    return allEvents.take(5).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// Start polling for new data every 5 seconds
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _refreshData();
    });
  }

  /// Load initial data from backend
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch statistics for the last hour
      final stats = await _apiService.getHourlyStatistics(widget.deviceId);

      // Fetch recent cough events
      final events = await _apiService.getCoughEvents(widget.deviceId);

      setState(() {
        _hourlyStats = stats;
        _recentEvents = _cleanRecentEvents(events);
        _isLoading = false;
      });

      print('✅ Data loaded: ${events.length} events');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data: $e';
      });
      print('❌ Error loading data: $e');
    }
  }

  /// Refresh data without showing loading indicator
  Future<void> _refreshData() async {
    try {
      // Fetch new statistics
      final stats = await _apiService.getHourlyStatistics(widget.deviceId);

      // Fetch new events
      final events = await _apiService.getCoughEvents(widget.deviceId);

      if (mounted) {
        setState(() {
          _hourlyStats = stats;
          _recentEvents = _cleanRecentEvents(events);
        });
      }

      print('🔄 Data refreshed');
    } catch (e) {
      print('❌ Error refreshing data: $e');
      // Don't update error message during background refresh
    }
  }

  /// Generate fake data for testing (single event)
  Future<void> _generateFakeData() async {
    setState(() {
      _isGeneratingData = true;
    });

    try {
      final result =
          await _apiService.generateDummyData(widget.deviceId, count: 1);
      print('✅ Generated ${result['eventsCreated']} fake cough event');

      // Refresh data after generation
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generated 1 cough event!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error generating fake data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Cough Count Analyzer'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading cough data...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Cough Count Analyzer'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final coughsPerHour = _hourlyStats?.coughsPerHour.toInt() ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      'Cough Count Analyzer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Waveform placeholder
                Center(
                  child: Image.asset(
                    'assets/images/waveform.png',
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.cyan.shade300,
                              Colors.cyan.shade100
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(Icons.graphic_eq,
                              size: 64, color: Colors.white),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Cough frequency circle
                Center(
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFDFF9FF),
                      border: Border.all(
                        color: const Color(0xFF9FE6FF),
                        width: 4,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 10,
                          offset: Offset(0, 6),
                          color: Color(0x22000000),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Cough\nfrequency\n$coughsPerHour/hour',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          height: 1.15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E2E2E),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // Cough spikes header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cough spikes',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    if (kDebugMode)
                      Text(
                        'Last ${_recentEvents.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Cough events list (clean + short, like the mock)
                if (_recentEvents.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No cough events detected yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Waiting for data from firmware...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...(_recentEvents.map((event) {
                    return _buildCoughEventCard(event);
                  }).toList()),

                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingData ? null : _generateFakeData,
                      icon: _isGeneratingData
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_chart),
                      label: Text(_isGeneratingData
                          ? 'Generating...'
                          : 'Generate Test Data'),
                    ),
                  ),
                ],

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on Cough Analyzer (Home)
              break;
            case 1:
              // Navigate to Device Screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeviceScreen(),
                ),
              );
              break;
            case 2:
              // Navigate to Trends & Summary
              // TODO: Implement PatientSummaryPage
              break;
          }
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wifi_tethering),
            label: 'Device',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Trends &\nsummary',
          ),
        ],
      ),
    );
  }

  Widget _buildCoughEventCard(CoughEvent event) {
    final timeFormat = DateFormat('HH:mm');
    final formattedTime = timeFormat.format(event.timestamp.toLocal());

    // Color cardColor;
    // String label;

    // switch (event.coughType.toLowerCase()) {
    //   case 'dry':
    //     cardColor = Colors.orange.shade100;
    //     label = 'Dry Cough';
    //     break;
    //   case 'wet':
    //     cardColor = Colors.cyan.shade100;
    //     label = 'Wet Cough';
    //     break;
    //   // ADD THIS CASE!
    //   case 'unknown':
    //   default:
    //     cardColor = Colors.red.shade50; // Light Red for Alert
    //     label = 'Cough Alert'; // Professional Label
    // }

    final Color cardColor = Colors.red.shade50;
    final String label = "Cough Alert";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 6),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF4A4A4A),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            formattedTime,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7A7A7A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
