import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'patient_allergies.dart';

class PatientUploadReports extends StatefulWidget {
  const PatientUploadReports({super.key});

  @override
  State<PatientUploadReports> createState() => _PatientUploadReportsState();
}

class _PatientUploadReportsState extends State<PatientUploadReports> {
  final List<String> _uploadedFiles = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Medical Reports',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Upload Medical Reports',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload any previous medical reports (optional)',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),

              // Upload Area
              GestureDetector(
                onTap: () {
                  setState(() {
                    _uploadedFiles.add('Medical_Report_${_uploadedFiles.length + 1}.pdf');
                  });
                },
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryTeal, width: 2, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.primaryTeal.withOpacity(0.05),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_upload_outlined, size: 64, color: AppTheme.primaryTeal),
                        const SizedBox(height: 16),
                        const Text(
                          'Tap to upload files',
                          style: TextStyle(fontSize: 16, color: AppTheme.primaryTeal, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Supported: PDF, JPG, PNG',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Uploaded Files List
              if (_uploadedFiles.isNotEmpty) ...[
                const Text('Uploaded Files:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ..._uploadedFiles.map((file) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.insert_drive_file, color: AppTheme.primaryTeal),
                        title: Text(file),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _uploadedFiles.remove(file);
                            });
                          },
                        ),
                      ),
                    )),
              ],

              const Spacer(),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PatientAllergies()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),

              // Skip Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PatientAllergies()),
                    );
                  },
                  child: Text('Skip for now', style: TextStyle(color: Colors.grey.shade600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
