import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'connection_success_screen.dart';

class AireaSetupScreen extends StatefulWidget {
  const AireaSetupScreen({super.key});

  @override
  State<AireaSetupScreen> createState() => _AireaSetupScreenState();
}

class _AireaSetupScreenState extends State<AireaSetupScreen> {
  static const String _boardHardwareId = 'ESP32_AIREA_01';
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isConnecting = false;
  Timer? _pollingTimer;
  String? _initialLastSeen; // We store the "old" timestamp here

  @override
  void initState() {
    super.initState();
    // Capture the current state of the board before we start
    _fetchInitialState();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 1. Get the "Old" Timestamp so we don't accidentally auto-connect
  Future<void> _fetchInitialState() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://airea-production.up.railway.app/api/board/status/$_boardHardwareId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _initialLastSeen = data['lastSeen']; // Save the stale time
        });
      }
    } catch (e) {
      // If fails (e.g. no internet), just assume no previous record
      _initialLastSeen = null;
    }
  }

  // Poll your Spring Boot backend to see if the device came online
  void _startPollingBackend() {
    int attempts = 0;
    const int maxAttempts = 15; // 30 seconds timeout

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      attempts++;

      try {
        final response = await http.get(
          Uri.parse(
              'https://airea-production.up.railway.app/api/board/status/$_boardHardwareId'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          String currentStatus = data['status'];
          String currentLastSeen = data['lastSeen'] ?? "";

          // --- SMART CHECK ---
          // Success ONLY if:
          // 1. Status is "online"
          // 2. The timestamp has CHANGED (meaning it's a fresh connection)
          bool isFreshConnection = (currentLastSeen != _initialLastSeen);

          if (currentStatus == 'online' && isFreshConnection) {
            timer.cancel();

            if (mounted) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('linked_device_id', _boardHardwareId);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Board Connected Successfully!'),
                  backgroundColor: Colors.green,
                ),
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const ConnectionSuccessScreen()),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Polling attempt $attempts: Waiting for board...');
      }

      if (attempts >= maxAttempts) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isConnecting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection timed out. Please try again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    });
  }

  Future<void> _sendCredentialsToESP32() async {
    if (_ssidController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both SSID and Password')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isConnecting = true;
    });

    // 2. Start asking Spring Boot if the device is online yet
    _startPollingBackend();

    // 3. Send the credentials to the board
    try {
      final url = Uri.parse('http://192.168.4.1/wifisave');
      await http.post(
        url,
        body: {
          's': _ssidController.text.trim(),
          'p': _passwordController.text,
        },
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Credentials sent. ESP32 is rebooting its Wi-Fi chip.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Airea Device'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 1: Connect to Board',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Go to your iPhone settings and connect to "Airea-Setup".\n\n'
              'IMPORTANT: If an Apple login screen pops up, hit "Cancel" and select "Use Without Internet". Then come back here.',
              style: TextStyle(fontSize: 15, color: Colors.redAccent),
            ),
            const SizedBox(height: 32),
            const Text(
              'Step 2: Enter Wi-Fi Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ssidController,
              enabled: !_isConnecting,
              decoration: const InputDecoration(
                labelText: 'Home Wi-Fi Name (SSID)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wifi),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              enabled: !_isConnecting,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Wi-Fi Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isConnecting ? null : _sendCredentialsToESP32,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF66A399),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isConnecting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Connecting...',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        ],
                      )
                    : const Text(
                        'Send to Airea Board',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500),
                      ),
              ),
            ),
            // We can keep the manual link as a backup
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ConnectionSuccessScreen()),
                  );
                },
                child: const Text(
                  "Device is already connected? Click here.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
