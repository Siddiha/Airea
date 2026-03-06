import 'package:flutter/material.dart';
import 'edit_doctor_details.dart';

class DoctorProfileFrame extends StatelessWidget {
  const DoctorProfileFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 70,
        color: Colors.white,
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home, color: Colors.black87),
              SizedBox(height: 4),
              Text("Home", style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Profile",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),

              // Edit Additional Details Button
              _buildButton(context, "Edit additional details"),

              const SizedBox(height: 18),
              _buildButton(context, "Manage connected patients"),

              const SizedBox(height: 18),
              _buildButton(context, "Logout"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF66A399),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
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
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
