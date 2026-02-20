import 'package:flutter/material.dart';

class DoctorProfileFrame extends StatelessWidget {
  const DoctorProfileFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Profile",
                  style: TextStyle(fontSize: 22)),
              const SizedBox(height: 30),
              _btn("Edit additional details"),
              const SizedBox(height: 15),
              _btn("Manage connected patients"),
              const SizedBox(height: 15),
              _btn("Logout"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(String text) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5DA092),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      onPressed: () {},
      child: Text(text),
    );
  }
}