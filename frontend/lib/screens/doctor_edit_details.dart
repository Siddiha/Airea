import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class DoctorEditDetails extends StatefulWidget {
  const DoctorEditDetails({Key? key}) : super(key: key);

  @override
  State<DoctorEditDetails> createState() => _DoctorEditDetailsState();
}

class _DoctorEditDetailsState extends State<DoctorEditDetails> {
  final _formKey = GlobalKey<FormState>();
  final _specializationsController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _specializationsController.dispose();
    _clinicAddressController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Additional Details',
          style: TextStyle(
            color: AppTheme.darkBlue,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                CustomTextField(
                  hintText: 'Specializations',
                  controller: _specializationsController,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  hintText: 'Clinic/hospital address',
                  controller: _clinicAddressController,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  hintText: 'Primary mobile number',
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  hintText: 'Email address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 40),
                CustomButton(
                  text: 'Confirm',
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Details updated successfully')),
                      );
                    }
                  },
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
