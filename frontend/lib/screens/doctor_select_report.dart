import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'doctor_view_report.dart';

class DoctorSelectReport extends StatelessWidget {
  const DoctorSelectReport({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reports = [
      'Medical Report - Jan 2025.pdf',
      'Lab Results - Dec 2024.pdf',
      'X-Ray Report - Nov 2024.pdf',
      'Blood Test - Oct 2024.pdf',
    ];

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
          'Past Medical Reports',
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
        child: ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoctorViewReport(
                      reportName: reports[index],
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: 30,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        reports[index],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.textSecondary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
