import 'package:flutter/material.dart';
import 'doctor_verification_frame.dart';

class DoctorMoreDetailsPage extends StatefulWidget {
  const DoctorMoreDetailsPage({super.key});

  @override
  State<DoctorMoreDetailsPage> createState() => _DoctorMoreDetailsPageState();
}

class _DoctorMoreDetailsPageState extends State<DoctorMoreDetailsPage> {
  final TextEditingController _specializationsController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _clinicAddressController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Please help us to know\nmore about you',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 40),

              // Specializations Field
              TextField(
                controller: _specializationsController,
                decoration: InputDecoration(
                  hintText: 'Specializations',
                  filled: true,
                  fillColor: const Color(0xFFD9D9D9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),

              const SizedBox(height: 16),

              // Medical License Number Field
              TextField(
                controller: _licenseController,
                decoration: InputDecoration(
                  hintText: 'Medical license number',
                  filled: true,
                  fillColor: const Color(0xFFD9D9D9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),

              const SizedBox(height: 16),

              // Clinic Address Field
              TextField(
                controller: _clinicAddressController,
                decoration: InputDecoration(
                  hintText: 'Clinic or hospital address',
                  filled: true,
                  fillColor: const Color(0xFFD9D9D9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),

              const SizedBox(height: 16),

              // Primary Mobile Number Field
              TextField(
                controller: _mobileController,
                decoration: InputDecoration(
                  hintText: 'Primary mobile number',
                  filled: true,
                  fillColor: const Color(0xFFD9D9D9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),

              const SizedBox(height: 16),

              // Email Address Field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Email address',
                  filled: true,
                  fillColor: const Color(0xFFD9D9D9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),

              const SizedBox(height: 40),

              // Finish Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DoctorVerificationFrame()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A5F), // Dark blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Finish',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
