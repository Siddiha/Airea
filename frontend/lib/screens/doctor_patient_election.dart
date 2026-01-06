import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/custom_button.dart';
import 'doctor_remove_confirmation.dart';

class DoctorPatientElection extends StatelessWidget {
  final String patientName;

  const DoctorPatientElection({
    Key? key,
    required this.patientName,
  }) : super(key: key);

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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                'Do you want to remove this patient from your list',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkBlue,
                ),
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'No',
                      onPressed: () => Navigator.pop(context),
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: CustomButton(
                      text: 'Yes',
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DoctorRemoveConfirmation(),
                          ),
                        );
                      },
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
