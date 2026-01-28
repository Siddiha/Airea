import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'cough_analyzer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _deviceIdController = TextEditingController(
    text: 'ESP32_COUGH_01', // Default device ID
  );
  final ApiService _apiService = ApiService();
  bool _isChecking = false;
  String? _errorMessage;

  Future<void> _connectToDevice() async {
    final deviceId = _deviceIdController.text.trim();

    if (deviceId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a device ID';
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      // Check if backend is reachable
      final isHealthy = await _apiService.checkHealth();

      if (!isHealthy) {
        //throw Exception('Backend is not responding');
      }

      // Navigate to cough analyzer screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CoughAnalyzerScreen(deviceId: deviceId),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Connection failed: $e\n\nMake sure backend is running!';
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.cyan.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monitor_heart_outlined,
                  size: 64,
                  color: Colors.cyan.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Airea Cough Monitor',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Connect to your device',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 48),

              // Device ID input
              TextField(
                controller: _deviceIdController,
                decoration: InputDecoration(
                  hintText: 'ESP32_COUGH_01',
                  labelText: 'Device ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.router),
                  errorText: _errorMessage,
                  errorMaxLines: 3,
                ),
                enabled: !_isChecking,
              ),
              const SizedBox(height: 24),

              // Connect button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _connectToDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Connect',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Make sure your ESP32 device is connected and the backend server is running.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }
}
