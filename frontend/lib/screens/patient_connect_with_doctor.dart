import 'package:flutter/material.dart';
import 'patient_pending_message.dart';
import 'patient_guidance_to_connect_with_doctor.dart';

class PatientConnectWithDoctor extends StatefulWidget {
  const PatientConnectWithDoctor({super.key});

  @override
  State<PatientConnectWithDoctor> createState() =>
      _PatientConnectWithDoctorState();
}

class _PatientConnectWithDoctorState
    extends State<PatientConnectWithDoctor> {
  int _selectedIndex = 0;

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // -------- BODY --------
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Please enter doctor’s id",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: 350,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'type',
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: 220,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientPendingMessage(),
                      ),
                    );
                  },
                  child: const Text("Confirm"),
                ),
              ),

              const SizedBox(height:100),

              const Text(
                "Please contact with doctor to get his/her id",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: 260,
              
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(24),
                ),
              ),
                  
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const PatientGuidanceToConnectWithDoctor(),
                      ),
                    );
                  },
                  child: const Text(
                    "Guidance to connect with doctor",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // -------- BOTTOM NAV --------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wifi),
            label: 'Device',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Trends & summary',
          ),
        ],
      ),
    );
  }
}