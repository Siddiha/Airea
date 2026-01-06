import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class DoctorAllergicConditions extends StatelessWidget {
  const DoctorAllergicConditions({Key? key}) : super(key: key);

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
          'Allergic Conditions',
          style: TextStyle(
            color: AppTheme.darkBlue,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient Allergies',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlue,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: AppTheme.highOrange.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.highOrange,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Known Allergies',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '• Penicillin - Severe reaction\n'
                    '• Pollen - Seasonal allergies\n'
                    '• Dust mites - Respiratory issues\n'
                    '• Peanuts - Mild to moderate reaction',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Always verify allergies before prescribing medication',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
