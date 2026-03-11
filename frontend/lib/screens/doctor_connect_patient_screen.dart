import 'package:flutter/material.dart';
import '../services/doctor_patient_service.dart';

class DoctorConnectPatientScreen extends StatefulWidget {
  const DoctorConnectPatientScreen({super.key});

  @override
  State<DoctorConnectPatientScreen> createState() =>
      _DoctorConnectPatientScreenState();
}

class _DoctorConnectPatientScreenState extends State<DoctorConnectPatientScreen> {
  int _step = 0; // 0: Confirmation, 1: Enter Details
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _patientNameController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _patientIdController.dispose();
    _patientNameController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    if (_patientIdController.text.isEmpty || _patientNameController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await DoctorPatientService.connectPatient(
        patientId: _patientIdController.text.trim(),
        patientName: _patientNameController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          // Show success and pop back to home
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patient connected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          setState(() =>
              _errorMessage = 'This patient is already connected or invalid');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: _step == 0
              ? _buildConfirmationStep()
              : _buildDetailsStep(),
        ),
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Do you want to connect\nwith a patient?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 50),
        _buildButton(
          label: 'Yes',
          onPressed: () => setState(() => _step = 1),
        ),
        const SizedBox(height: 20),
        _buildButton(
          label: 'No',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            "Connect with a Patient",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          const Text(
            "Enter Patient ID",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          _customTextField(
            controller: _patientIdController,
            hintText: 'e.g., P123456',
            enabled: !_isLoading,
          ),
          const SizedBox(height: 30),
          const Text(
            "Patient Name",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          _customTextField(
            controller: _patientNameController,
            hintText: 'Enter patient name',
            enabled: !_isLoading,
          ),
          const SizedBox(height: 20),
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 30),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildButton(
                  label: 'Connect',
                  onPressed: _handleConnect,
                ),
          const SizedBox(height: 15),
          _buildButton(
            label: 'Back',
            onPressed: () => setState(() => _step = 0),
            isSecondary: true,
          ),
        ],
      ),
    );
  }

  Widget _customTextField({
    required TextEditingController controller,
    required String hintText,
    required bool enabled,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFD9E2E8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary
              ? Colors.grey.shade300
              : const Color(0xFF66A399),
          foregroundColor: isSecondary ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
