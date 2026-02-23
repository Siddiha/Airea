import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'device_screen.dart'; // Make sure this path is correct for your project

class AireaSetupScreen extends StatefulWidget {
  const AireaSetupScreen({super.key});

  @override
  State<AireaSetupScreen> createState() => _AireaSetupScreenState();
}

class _AireaSetupScreenState extends State<AireaSetupScreen> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isConnecting = false;
  Timer? _pollingTimer;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Poll your Spring Boot backend to see if the device came online
  void _startPollingBackend() {
    int attempts = 0;
    const int maxAttempts =
        15; // 15 attempts * 2 seconds = 30 seconds total timeout

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      attempts++;

      try {
        // TODO: Replace this URL with your actual Spring Boot Railway endpoint
        final response = await http.get(
          Uri.parse(
              'https://your-airea-app.up.railway.app/api/device/status/airea_board_001'),
        );

        if (response.statusCode == 200) {
          // Parse the JSON to ensure the status is actually "online"
          final data = jsonDecode(response.body);

          if (data['status'] == 'online') {
            timer.cancel(); // Stop checking!

            if (mounted) {
              // 1. Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Board Connected Successfully!'),
                  backgroundColor: Colors.green,
                ),
              );

              // 2. Navigate to the Device Screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DeviceScreen()),
              );
            }
          }
        }
      } catch (e) {
        // Backend hasn't updated yet or isn't reachable, we just wait for the next tick.
        debugPrint('Polling attempt $attempts: Waiting for board...');
      }

      // Handle Timeout if the board never connects
      if (attempts >= maxAttempts) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isConnecting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Connection timed out. Please check your Wi-Fi password and try again.'),
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

    // Hide the keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isConnecting = true;
    });

    // 1. Start asking Spring Boot if the device is online yet
    _startPollingBackend();

    // 2. Send the credentials to the board
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
      // This catch block is EXPECTED to trigger!
      // When the ESP32 receives the credentials, it instantly drops its "Airea-Setup" network
      // to connect to your home Wi-Fi, which abruptly cuts off the HTTP response to your phone.
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
                            'Connecting to Board...',
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
          ],
        ),
      ),
    );
  }
}
