import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'patient_device_connected.dart';
import 'patient_device_guidance.dart';
import '../models/device_model.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';
import '../widgets/bottom_nav_bar.dart';


class PatientConnectDeviceCode extends StatefulWidget {
  const PatientConnectDeviceCode({super.key});

  @override
  State<PatientConnectDeviceCode> createState() => _PatientConnectDeviceCodeState();
}

class _PatientConnectDeviceCodeState extends State<PatientConnectDeviceCode> {
  final TextEditingController _codeController = TextEditingController();
  final DeviceController _deviceLogic = DeviceController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _codeError;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height - 100,
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // 1. Title Text
                const Text(
                  'Please enter unique\ncode ID provided for\nthe wearable device',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 30),

                // 2. Input Field
                TextField(
                  controller: _codeController,
                  textAlign: TextAlign.left,
                  keyboardType: TextInputType.text,
                  onChanged: (_) => setState(() => _codeError = null),
                  decoration: InputDecoration(
                    hintText: 'Enter device code',
                    labelText: 'Device ID',
                    hintStyle: const TextStyle(color: Colors.black38, fontSize: 16),
                    filled: true,
                    fillColor: AppTheme.inputFillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
                    errorText: _codeError,
                    errorStyle: const TextStyle(fontSize: 12),
                  ),
                  style: const TextStyle(fontSize: 18),
                ),

                const SizedBox(height: 30),

                // 3. Confirm Button
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      String input = _codeController.text.trim();

                      if (input.isEmpty) {
                        setState(() => _codeError = 'Please enter the device code');
                        return;
                      }

                      setState(() {
                        _isLoading = true;
                        _codeError = null;
                      });

                      try {
                        // Verify the device exists in the backend
                        final device = await _apiService.getDevice(input);
                        if (device == null) {
                          setState(() {
                            _codeError = 'Device not found. Please verify the device ID.';
                            _isLoading = false;
                          });
                          return;
                        }

                        // Validate locally and save to SharedPreferences + Supabase
                        _deviceLogic.pairDevice(input);
                        await ProfileService.saveLinkedDevice(input);

                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PatientDeviceConnected(),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Connection error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        setState(() => _isLoading = false);
                      }
                    },
                    style: AppTheme.primaryButton(),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Confirm'),
                  ),
                ),

                const Spacer(flex: 2),

                // 4. Bottom Info Text
                const Text(
                  'Get unique code from the\nuser manual provided with\nthe wearable device',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 20),

                // 5. Guidance Button
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PatientDeviceGuidance(),
                        ),
                      );
                    },
                    style: AppTheme.secondaryButton(),
                    child: const Text('Guidance'),
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const PatientBottomNav(currentIndex: 1),
    );
  }
}
