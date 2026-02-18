import 'package:flutter/material.dart';
import '../models/doctor_details.dart';

class DoctorMoreDetails extends StatefulWidget {
  const DoctorMoreDetails({super.key});

  @override
  State<DoctorMoreDetails> createState() => _DoctorMoreDetailsState();
}

class _DoctorMoreDetailsState extends State<DoctorMoreDetails> {
  // ── Controllers for each field ──
  final _specializationController = TextEditingController();
  final _licenseController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController= TextEditingController();
  final _emailController = TextEditingController();

  // ── Track which fields have been flagged as empty after pressing Finish ──
  final Set<String> _emptyFlags = {};

  @override
  void dispose() {
    _specializationController.dispose();
    _licenseController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────
  // Finish pressed — validate and show empty fields
  // ────────────────────────────────────────────────

  void _onFinish() {
    // Build a DoctorDetails object from current field values.
    final details = DoctorDetails(
      specialization:          _specializationController.text,
      medicalLicenseNumber:    _licenseController.text,
      clinicOrHospitalAddress: _addressController.text,
      primaryMobileNumber:     _mobileController.text,
      emailAddress:            _emailController.text,
    );

    final empty = details.emptyFields;

    if (empty.isNotEmpty) {
      // Highlight empty fields and show a snackbar listing them.
      setState(() {
        _emptyFlags
          ..clear()
          ..addAll(empty);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1A2B5F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please fill in the following fields:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              ...empty.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.white70),
                      const SizedBox(width: 8),
                      Text(
                        field,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // All fields filled — data is saved in [details].
    // Navigation / next action goes here.
  }

  // ────────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Doctor  More details about doctor',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // ── Heading ──
              const Text(
                'Please help us to know\nmore about you',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 40),

              // ── Form fields ──
              Expanded(
                child: ListView(
                  children: [
                    _buildField(
                      controller: _specializationController,
                      label: 'Specializations',
                      flagKey: 'Specializations',
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _licenseController,
                      label: 'Medical license number',
                      flagKey: 'Medical license number',
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _addressController,
                      label: 'Clinic or hospital address',
                      flagKey: 'Clinic or hospital address',
                      keyboardType: TextInputType.streetAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _mobileController,
                      label: 'Primary mobile number',
                      flagKey: 'Primary mobile number',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _emailController,
                      label: 'Email address',
                      flagKey: 'Email address',
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Finish button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2B5F), // dark navy
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Finish',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // Reusable field builder
  // ────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String flagKey,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isEmpty = _emptyFlags.contains(flagKey);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      // Clear the flag for this field as soon as user starts typing.
      onChanged: (_) {
        if (isEmpty) {
          setState(() => _emptyFlags.remove(flagKey));
        }
      },
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          color: isEmpty ? Colors.red.shade400 : Colors.black54,
          fontSize: 15,
        ),
        filled: true,
        fillColor: isEmpty
            ? const Color(0xFFFFEBEE) // light red tint when empty
            : const Color(0xFFE8EAF0), // default grey-blue from Figma
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: isEmpty
              ? BorderSide(color: Colors.red.shade300, width: 1.2)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: isEmpty
                ? Colors.red.shade400
                : const Color(0xFF1A2B5F),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
