import 'package:flutter/material.dart';
import 'package:airea_cough_monitor/screens/styling.dart';
import 'patient_notifications.dart';
import 'patient_profile.dart';
import 'patient_cough_count.dart';
import 'patient_connect_device_option.dart';
import 'patient_summary_page.dart';

class patientHomeScreen extends StatefulWidget {
  const patientHomeScreen({super.key});

  @override
  State<patientHomeScreen> createState() => _patientHomeScreen();
}

class _patientHomeScreen extends State<patientHomeScreen> {
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
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person, size: 40),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PatientProfile()),
            );
          },
        ),
        title: const Text("Hello User !"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PatientNotifications()),
              );
            },
            icon: const Icon(Icons.notifications_active_sharp),
            iconSize: 40,
            color: Colors.black,
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1, 
                    child: Column(
                      children: [
                        VitalCard(
                          title: "Spo2",
                          status: spo2Status,
                          value: "$spo2%",
                          icon: Icons.water_drop_outlined,
                          color: Colors.green,
                          Cardheight: 90,
                        ),
                        const SizedBox(
                          height: 10,
                        ), 
                        VitalCard(
                          title: "Temperature",
                          Cardheight: 100,
                          status: temperatureStatus,
                          value: "$temperature°C",
                          icon: Icons.thermostat,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ), 
                  Expanded(
                    flex: 1, 
                    child: VitalCard(
                      title: "Heart Rate",
                      Cardheight:190,
                      value: "$heartRate BPM",
                      status: heartRateStatus,
                      icon: Icons.show_chart,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const SizedBox(height: 10,),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PatientCoughCount()),
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
              )
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
              // Already on home
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PatientConnectDeviceOption()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PatientSummaryPage()),
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
