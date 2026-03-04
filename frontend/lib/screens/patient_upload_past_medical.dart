import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../models/medical_report_model.dart';
import '../models/registration_data.dart';
import '../services/profile_service.dart';
import 'patient_allergies_entry.dart';

class UploadReportsScreen extends StatefulWidget {
  final RegistrationData? registrationData;

  const UploadReportsScreen({
    Key? key,
    this.registrationData,
  }) : super(key: key);

  @override
  State<UploadReportsScreen> createState() => _UploadReportsScreenState();
}

class _UploadReportsScreenState extends State<UploadReportsScreen> {
  final MedicalReportService _reportService = MedicalReportService();
  bool _isUploading = false;
  List<String> _uploadedFilePaths = [];

  Future<void> _pickAndSaveFiles() async {
    setState(() => _isUploading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        int addedCount = 0;
        for (PlatformFile file in result.files) {
          if (file.path == null) continue;

          final String filePath = file.path!;
          final String fileName = file.name;
          final String extension = p.extension(filePath).toLowerCase();
          final String id = DateTime.now().millisecondsSinceEpoch.toString();

          MedicalDocument? newDoc;

          // OOAD Factory Logic
          if (extension == '.pdf') {
            newDoc = PdfMedicalReport(
              id: id,
              fileName: fileName,
              dateAdded: DateTime.now(),
              filePath: filePath,
            );
          } else if (['.jpg', '.jpeg', '.png'].contains(extension)) {
            newDoc = ImageMedicalReport(
              id: id,
              fileName: fileName,
              dateAdded: DateTime.now(),
              filePath: filePath,
            );
          }

          if (newDoc != null) {
            _reportService.addReport(newDoc);
            _uploadedFilePaths.add(filePath);
            addedCount++;
          }
        }

        if (mounted && addedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$addedCount file(s) added!')),
          );
        }
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _handleContinue() async {
    // Save medical report paths locally for later access from profile screen
    await ProfileService.saveMedicalReports(_uploadedFilePaths);

    // Update registration data with medical report paths
    final updatedData = widget.registrationData!.copyWith(
      medicalReportPaths: _uploadedFilePaths,
    );

    // Navigate to allergies page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientAllergies(registrationData: updatedData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Upload past medical\nreports if available",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _isUploading ? null : _pickAndSaveFiles,
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E7EB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator())
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle, color: Color(0xFF21A658), size: 80),
                            SizedBox(height: 10),
                            Text("Press to\nadd file/s", textAlign: TextAlign.center),
                          ],
                        ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D214F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Next", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}