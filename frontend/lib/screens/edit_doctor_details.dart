import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class EditDoctorDetails extends StatelessWidget {
  const EditDoctorDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Edit additionally\nprovided details",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 40),
              _labeledField("Specializations"),
              const SizedBox(height: 20),
              _labeledField("Clinic or hospital address"),
              const SizedBox(height: 20),
              _labeledField("Primary mobile number"),
              const SizedBox(height: 20),
              _labeledField("Email address"),
              const SizedBox(height: 40),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  style: AppTheme.primaryButton(),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labeledField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFE8EAF0),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}