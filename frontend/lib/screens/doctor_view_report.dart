import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class DoctorViewReport extends StatelessWidget {
  final String reportName;

  const DoctorViewReport({
    Key? key,
    required this.reportName,
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
        title: Text(
          reportName,
          style: const TextStyle(
            color: AppTheme.darkBlue,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 100,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 20),
            const Text(
              'PDF Viewer',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                reportName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'PDF content would be displayed here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
