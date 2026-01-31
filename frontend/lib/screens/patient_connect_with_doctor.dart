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

    // You can add navigation later if needed
    // Example:
    // if (index == 1) Navigator.push(...)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  BOTTOM NAVIGATION BAR
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
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),

      //  BODY (your existing UI)
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
         crossAxisAlignment: CrossAxisAlignment.center, // horizontal alignment
          children: [
            const Text(
                    "Please enter doctor’s id",
                     textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, 
                fontWeight: FontWeight.w600
          ),
           
      ),
       const SizedBox(height: 8),
           Container(
            width:350,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'type',
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),),
           const SizedBox(height: 20),
               Container(
                width:250,
               child :ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PatientPendingMessage(),
                  ),

                );
              },
               
              child: const Text('Confirm'),
            ),),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const PatientGuidanceToConnectWithDoctor(),
                  ),
                );
              },
              child: const Text('Guidance to connect with doctor'),
            ),
          ],
        ),
      ),
    );
  }
}