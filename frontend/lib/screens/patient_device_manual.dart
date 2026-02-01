import 'package:flutter/material.dart';

class PatientDeviceManual extends StatefulWidget {
  const PatientDeviceManual({super.key});

  @override
  State<PatientDeviceManual> createState() => _PatientDeviceManualState();
}

class _PatientDeviceManualState extends State<PatientDeviceManual> {
  // 1. Controller for the scrollbar
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Row (Title + Close Button) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'User manual',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context); 
                    },
                    icon: const Icon(Icons.close, size: 30, color: Colors.black),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 20, right: 10, top: 20, bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4), 
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  // 2. Scrollbar Widget
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true, 
                    thickness: 6.0,
                    radius: const Radius.circular(10),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(), 
                      padding: const EdgeInsets.only(right: 15.0), 
                      child: const Text(
                        "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40), 
            ],
          ),
        ),
      ),
    );
  }
}