import 'package:flutter/material.dart';

class PatientDeviceManual extends StatefulWidget {
  const PatientDeviceManual({super.key});

  @override
  State<PatientDeviceManual> createState() => _PatientDeviceManualState();
}

class _PatientDeviceManualState extends State<PatientDeviceManual> {
  // 1. Controller for the scrollbar
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Row (Title + Close Button) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'User manual',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context); 
                    },
                    icon: const Icon(Icons.close, size: 30, color: Colors.black),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 20, right: 10, top: 20, bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4), 
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  // 2. Scrollbar Widget
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true, 
                    thickness: 6.0,
                    radius: const Radius.circular(10),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(), 
                      padding: const EdgeInsets.only(right: 15.0), 
                      child: const Text(
                        "Airea Wearable Health Monitor\n\n"
                        "Getting Started\n"
                        "1. Charge the device fully before first use using the provided USB-C cable.\n"
                        "2. Wear the device on your wrist or chest strap as directed by your doctor.\n"
                        "3. Ensure the sensor pads make contact with your skin for accurate readings.\n\n"
                        "Features\n"
                        "• Heart Rate Monitoring — Continuously tracks your heart rate in BPM.\n"
                        "• Temperature Sensing — Measures body temperature in real time.\n"
                        "• Cough Detection — Uses an onboard microphone and AI model to detect and count coughs.\n"
                        "• Fall Detection — Detects sudden falls and sends emergency alerts to your doctor and emergency contact.\n\n"
                        "LED Indicators\n"
                        "• Solid Green — Device is active and connected.\n"
                        "• Blinking Blue — Attempting to connect to the server.\n"
                        "• Red — Low battery or sensor error.\n\n"
                        "Troubleshooting\n"
                        "• If readings show 'No Data', ensure the device is worn correctly and the sensor pads are clean.\n"
                        "• If the device won't turn on, charge it for at least 30 minutes.\n"
                        "• If connection is lost, restart the device by holding the side button for 5 seconds.\n\n"
                        "Safety\n"
                        "• This device is for health monitoring purposes only and is not a medical diagnostic tool.\n"
                        "• Keep the device dry — remove before showering or swimming.\n"
                        "• If you experience skin irritation, discontinue use and consult your doctor.\n\n"
                        "Support\n"
                        "For technical support, contact our team or speak with your connected doctor through the app.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40), 
            ],
          ),
        ),
      ),
    );
  }
}