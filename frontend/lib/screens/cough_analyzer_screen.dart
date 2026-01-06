import 'package:flutter/material.dart';
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        const Text(
                          'Cough count analyzer',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Waveform visualization
                        _buildWaveformSection(),
                        const SizedBox(height: 30),

                        // Cough frequency circle
                        Center(child: _buildCoughFrequencyCard()),
                        const SizedBox(height: 30),

                        // Cough spikes section
                        Expanded(child: _buildCoughSpikesSection()),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: _buildBottomNavBar(),
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
    return Center(
      child: CustomPaint(
        size: const Size(300, 100),
        painter: WaveformPainter(),
      ),
    );
  }

  Widget _buildCoughFrequencyCard() {
    final coughsPerHour = _hourlyStats?.coughsPerHour.toInt() ?? 50;

    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFB3E5FC), // Light cyan
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Cough\nfrequency',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$coughsPerHour/hour',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
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
        const Text(
          'Cough spikes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _recentEvents.isEmpty
              ? const Center(
                  child: Text(
                    'No cough events detected yet',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : ListView(
                  children: [
                    _buildCoughSpikeCard('Dry Cough', '13:00'),
                    const SizedBox(height: 12),
                    _buildCoughSpikeCard('Dry Cough', '12:56'),
                    const SizedBox(height: 12),
                    _buildCoughSpikeCard('Wet Cough', '12:48'),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildCoughSpikeCard(String type, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Light gray
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            type,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.wifi),
          label: 'Device',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.article_outlined),
          label: 'Trends &\nsummary',
        ),
      ],
    );
  }
}

// Custom Waveform Painter
class WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00BCD4) // Cyan
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final amplitude = size.height / 3;
    final frequency = 8;
    final step = size.width / 100;

    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x += step) {
      // Create varying wave heights to simulate waveform
      double heightMultiplier = 1.0;
      if (x > size.width * 0.15 && x < size.width * 0.25) {
        heightMultiplier = 1.5; // Taller spike
      } else if (x > size.width * 0.4 && x < size.width * 0.6) {
        heightMultiplier = 2.0; // Tallest spike
      } else if (x > size.width * 0.75 && x < size.width * 0.85) {
        heightMultiplier = 1.3; // Medium spike
      }

      final y = size.height / 2 +
          amplitude * heightMultiplier * Math.sin((x / size.width) * frequency * 2 * Math.pi);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Math helper
class Math {
  static double sin(double x) => x.sin();
  static double get pi => 3.14159265359;
}

extension MathExtension on double {
  double sin() {
    // Simple sine approximation
    double x = this;
    while (x > Math.pi) x -= 2 * Math.pi;
    while (x < -Math.pi) x += 2 * Math.pi;

    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }
}
