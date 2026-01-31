import 'package:flutter/material.dart';

class PatientGuidanceToConnectWithDoctor extends StatelessWidget {
  const PatientGuidanceToConnectWithDoctor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guidance to connect'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'Please contact your doctor directly and request '
            'his/her Doctor ID. Enter the provided ID to '
            'initiate the connection.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}