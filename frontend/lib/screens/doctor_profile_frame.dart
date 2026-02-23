import 'package:flutter/material.dart';
import 'edit_doctor_details.dart';

class DoctorProfileFrame extends StatelessWidget {
  const DoctorProfileFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF0),

      // Bottom Home Button
      bottomNavigationBar: GestureDetector(
        onTap: () {
          Navigator.pop(context); // Go back to Home
        },
        child: Container(
          height: 60,
          color: Colors.white,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home),
              Text("Home"),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Profile", style: TextStyle(fontSize: 22)),
              const SizedBox(height: 30),

              // 🔹 Edit Additional Details Button
              _btn(context, "Edit additional details"),

              const SizedBox(height: 15),
              _btn(context, "Manage connected patients"),

              const SizedBox(height: 15),
              _btn(context, "Logout"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(BuildContext context, String text) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5DA092),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      onPressed: () {
        if (text == "Edit additional details") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EditDoctorDetails(),
            ),
          );
        }
      },
      child: Text(text),
    );
  }
}
