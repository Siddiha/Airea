import 'package:flutter/material.dart';
import 'package:airea_cough_monitor/screens/styling.dart';

import 'patient_notifications.dart';
import 'patient_profile.dart';
import 'patient_cough_count.dart';
import 'patient_connect_device_option.dart';
import 'patient_summary_page.dart';
import 'cough_analyzer_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int spo2 = 98;
  String spo2Status = "Normal";

  int heartRate = 72;
  String heartRateStatus = "Normal";

  double temperature = 34.0;
  String temperatureStatus = "Normal";

  int coughCount = 600;
  String coughStatus = "Normal";

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person, size: 40),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PatientProfile(),
              ),
            );
          },
        ),
        title: const Text("Hello User!"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_sharp),
            iconSize: 40,
            color: Colors.black,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PatientNotifications(),
                ),
              );
            },
          ),
          const SizedBox(width: 30),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Live vitals",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        VitalCard(
                          title: "SpO₂",
                          status: spo2Status,
                          value: "$spo2%",
                          icon: Icons.water_drop_outlined,
                          color: Colors.green,
                          Cardheight: 90,
                        ),
                        const SizedBox(height: 10),
                        VitalCard(
                          title: "Temperature",
                          status: temperatureStatus,
                          value: "$temperature°C",
                          icon: Icons.thermostat,
                          color: Colors.green,
                          Cardheight: 100,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: VitalCard(
                      title: "Heart Rate",
                      status: heartRateStatus,
                      value: "$heartRate BPM",
                      icon: Icons.show_chart,
                      color: Colors.green,
                      Cardheight: 190,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CoughAnalyzerScreen(
                        deviceId: 'ESP32_COUGH_01',
                      ),
                    ),
                  );
                },
                child: vitalCardWithButton(
                  Cardheight: 130,
                  btnText: "View Cough Trends",
                  color: Colors.orange,
                  status: coughStatus,
                  title: "Cough",
                  value: coughCount.toString(),
                  statusColor: Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PatientConnectDeviceOption(),
                ),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PatientSummaryPage(),
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.watch),
            label: 'Device',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Trends',
          ),
        ],
      ),
    );
  }
}
