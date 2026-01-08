import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cough_event.dart';
import '../models/cough_statistics.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import 'dart:math' as math;

class CoughAnalyzerScreen extends StatefulWidget {
  final String deviceId;

  const CoughAnalyzerScreen({
    super.key,
    this.deviceId = ApiConfig.defaultDeviceId,
  });

  @override
  State<CoughAnalyzerScreen> createState() => _CoughAnalyzerScreenState();
}

class _CoughAnalyzerScreenState extends State<CoughAnalyzerScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  CoughStatistics? _hourlyStats;
  List<CoughEvent> _recentEvents = [];

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
      final stats = await _apiService.getHourlyStatistics(widget.deviceId);
      final events = await _apiService.getCoughEvents(widget.deviceId);

      setState(() {
        _hourlyStats = stats;
        _recentEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data: $e';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
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
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
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
          colors: [AppTheme.primaryTeal.withOpacity(0.6), AppTheme.primaryTeal.withOpacity(0.2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(double.infinity, 80),
          painter: WaveformPainter(),
        ),
      ),
    );
  }

  Widget _buildCoughFrequencyCard() {
    final coughsPerHour = _hourlyStats?.coughsPerHour.toInt() ?? 0;
    final color = _getColorForFrequency(coughsPerHour.toDouble());

    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 6),
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
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForFrequency(double frequency) {
    if (frequency > 50) return AppTheme.criticalRed;
    if (frequency > 20) return AppTheme.highOrange;
    return AppTheme.normalGreen;
  }

  Widget _buildStatisticsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard('Total', _hourlyStats?.totalCoughs ?? 0, Colors.blue),
        _buildStatCard('Dry', _hourlyStats?.dryCoughs ?? 0, AppTheme.highOrange),
        _buildStatCard('Wet', _hourlyStats?.wetCoughs ?? 0, AppTheme.primaryTeal),
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
        border: Border.all(color: color.withOpacity(0.3)),
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
        cardColor = AppTheme.highOrange.withOpacity(0.2);
        icon = Icons.air;
        break;
      case 'wet':
        cardColor = AppTheme.primaryTeal.withOpacity(0.2);
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

// Custom Waveform Painter
class WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryTeal
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final amplitude = size.height / 3;
    final frequency = 8;
    final step = size.width / 100;

    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x += step) {
      double heightMultiplier = 1.0;
      if (x > size.width * 0.15 && x < size.width * 0.25) {
        heightMultiplier = 1.5;
      } else if (x > size.width * 0.4 && x < size.width * 0.6) {
        heightMultiplier = 2.0;
      } else if (x > size.width * 0.75 && x < size.width * 0.85) {
        heightMultiplier = 1.3;
      }

      final y = size.height / 2 +
          amplitude *
              heightMultiplier *
              math.sin((x / size.width) * frequency * 2 * math.pi);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
