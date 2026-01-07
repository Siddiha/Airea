import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/cough_statistics.dart';
import '../models/cough_event.dart';

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
  bool _isLoading = false;
  final String _errorMessage = '';
  CoughStatistics? _hourlyStats;
  final List<CoughEvent> _recentEvents = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Placeholder: call API service as needed. Keep minimal to avoid changing behavior.
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() => _isLoading = false);
  }

  // Dummy data (UI-only today)
  int get coughFrequencyPerHour => 50;

  List<_CoughSpike> get coughSpikes => const [
        _CoughSpike(type: 'Dry Cough', time: '13:00'),
        _CoughSpike(type: 'Dry Cough', time: '12:56'),
        _CoughSpike(type: 'Wet Cough', time: '12:48'),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              const Text(
                'Cough count analyzer',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Image.asset(
                  'assets/images/waveform.png',
                  height: 160,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
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
                      'Cough\nfrequency\n$coughFrequencyPerHour/hour',
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
              const Text(
                'Cough spikes',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(top: 6, bottom: 10),
                  itemCount: coughSpikes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final spike = coughSpikes[index];
                    return _SpikeCard(type: spike.type, time: spike.time);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (_) {},
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
}

class _SpikeCard extends StatelessWidget {
  final String type;
  final String time;

  const _SpikeCard({
    required this.type,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FBFF),
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
            type,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF4A4A4A),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            time,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF7A7A7A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoughSpike {
  final String type;
  final String time;

  const _CoughSpike({required this.type, required this.time});
}
