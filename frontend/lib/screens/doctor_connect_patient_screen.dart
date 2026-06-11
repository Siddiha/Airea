import 'package:flutter/material.dart';
import '../config/app_theme.dart';
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
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _patientIdController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    final patientCode = _patientIdController.text.trim();
    final codeRegex = RegExp(r'^[a-zA-Z0-9_-]+$');

    if (patientCode.isEmpty) {
      setState(() => _errorMessage = 'Please enter the patient code');
      return;
    }

    if (!codeRegex.hasMatch(patientCode)) {
      setState(() => _errorMessage = 'Code can only contain letters, numbers, hyphens, and underscores');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final error = await DoctorPatientService.connectPatient(
        patientCode: _patientIdController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patient connected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          setState(() => _errorMessage = error);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: Could not connect. Is the server running?';
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
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 60),
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
          const SizedBox(height: 5),
          const Text(
            "Connect with a Patient",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          const Text(
            "Enter Patient Code",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          _customTextField(
            controller: _patientIdController,
            hintText: 'e.g., P001',
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
              : SizedBox(
                  height: AppTheme.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _handleConnect,
                    style: AppTheme.primaryButton(),
                    child: const Text('Connect'),
                  ),
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
        labelText: 'Patient Code',
        filled: true,
        fillColor: AppTheme.inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 1.5),
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
      height: AppTheme.buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: isSecondary ? AppTheme.secondaryButton() : AppTheme.secondaryButton(),
        child: Text(label),
      ),
    );
  }
}
