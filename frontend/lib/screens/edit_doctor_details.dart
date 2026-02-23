import 'package:flutter/material.dart';

class EditDoctorDetails extends StatelessWidget {
  const EditDoctorDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF0),

    

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  "Edit additionally\nprovided details",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 30),

                _textField("Specializations"),
                const SizedBox(height: 15),
                _textField("Clinic or hospital address"),
                const SizedBox(height: 15),
                _textField("Primary mobile number"),
                const SizedBox(height: 15),
                _textField("Email address"),

                const SizedBox(height: 40),

                SizedBox(
                  width: 160,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2D4E),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Confirm"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(String hint) {
    return SizedBox(
      width: 260,
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[300],
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 15, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}