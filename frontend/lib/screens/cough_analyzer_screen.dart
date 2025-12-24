import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cough_event.dart';
import '../models/cough_statistics.dart';
import '../services/api_service.dart';

class CoughAnalyzerScreen extends StatefulWidget {
  final String deviceId;

  const CoughAnalyzerScreen({super.key, required this.deviceId});

  @override
  State<CoughAnalyzerScreen> createState() => _CoughAnalyzerScreenState();
}

class _CoughAnalyzerScreenState extends State<CoughAnalyzerScreen> {
  final ApiService _apiService = ApiService();

  CoughStatistics? _hourlyStats;
  List<CoughEvent> _recentEvents = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load hourly statistics
      final stats = await _apiService.getHourlyStatistics(widget.deviceId);

      // Load recent events (last hour)
      final events = await _apiService.getCoughEventsByTimeRange(
        widget.deviceId,
        DateTime.now().subtract(const Duration(hours: 1)),
        DateTime.now(),
      );

      setState(() {
        _hourlyStats = stats;
        _recentEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Cough count analyzer'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? _buildErrorView()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWaveformSection(),
                    const SizedBox(height: 32),
                    _buildCoughFrequencyCard(),
                    const SizedBox(height: 32),
                    _buildStatisticsRow(),
                    const SizedBox(height: 32),
                    _buildCoughSpikesSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorView() {
    return Center(
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
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformSection() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyan.shade300, Colors.cyan.shade100],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.graphic_eq, size: 64, color: Colors.white),
      ),
    );
  }

  Widget _buildCoughFrequencyCard() {
    final coughsPerHour = _hourlyStats?.coughsPerHour.toInt() ?? 0;

    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.cyan.shade50,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Cough\nfrequency',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Text(
              '$coughsPerHour/hour',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.cyan.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard('Total', _hourlyStats?.totalCoughs ?? 0, Colors.blue),
        _buildStatCard('Dry', _hourlyStats?.dryCoughs ?? 0, Colors.orange),
        _buildStatCard('Wet', _hourlyStats?.wetCoughs ?? 0, Colors.cyan),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoughSpikesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cough spikes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Last ${_recentEvents.length} events',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recentEvents.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No cough events detected yet'),
            ),
          )
        else
          ..._recentEvents.take(10).map((event) {
            return _buildCoughEventCard(event);
          }).toList(),
      ],
    );
  }

  Widget _buildCoughEventCard(CoughEvent event) {
    final timeFormat = DateFormat('HH:mm');
    final confidence = (event.confidence * 100).toInt();

    Color cardColor;
    IconData icon;

    switch (event.coughType.toLowerCase()) {
      case 'dry':
        cardColor = Colors.orange.shade100;
        icon = Icons.air;
        break;
      case 'wet':
        cardColor = Colors.cyan.shade100;
        icon = Icons.water_drop;
        break;
      default:
        cardColor = Colors.grey.shade100;
        icon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${event.coughType} Cough',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$confidence% confidence',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            timeFormat.format(event.timestamp),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
