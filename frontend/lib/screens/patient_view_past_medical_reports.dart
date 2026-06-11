import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
// Adjust import to match your folder structure
import '../models/medical_report_model.dart';
import '../services/profile_service.dart';

class ViewReportsScreen extends StatefulWidget {
  const ViewReportsScreen({Key? key}) : super(key: key);

  @override
  State<ViewReportsScreen> createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  List<MedicalDocument> reports = [];
  List<String> _filePaths = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    // Load file paths from ProfileService
    _filePaths = await ProfileService.loadMedicalReports();
    
    // Convert to MedicalDocument objects
    final docs = <MedicalDocument>[];
    for (final filePath in _filePaths) {
      final fileName = p.basename(filePath);
      final extension = p.extension(filePath).toLowerCase();
      final id = filePath.hashCode.toString();

      MedicalDocument? doc;
      if (extension == '.pdf') {
        doc = PdfMedicalReport(
          id: id,
          fileName: fileName,
          dateAdded: DateTime.now(),
          filePath: filePath,
        );
      } else if (['.jpg', '.jpeg', '.png'].contains(extension)) {
        doc = ImageMedicalReport(
          id: id,
          fileName: fileName,
          dateAdded: DateTime.now(),
          filePath: filePath,
        );
      }
      if (doc != null) {
        docs.add(doc);
      }
    }
    
    setState(() {
      reports = docs;
    });
  }

  Future<void> _uploadNewFiles() async {
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
          if (!_filePaths.contains(file.path!)) {
            _filePaths.add(file.path!);
            addedCount++;
          }
        }

        if (addedCount > 0) {
          // Save to ProfileService
          await ProfileService.saveMedicalReports(_filePaths);
          // Reload the list
          await _loadReports();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$addedCount file(s) added!')),
            );
          }
        }
      }
    } catch (e) {
      print("Error uploading files: $e");
    }
  }

  Future<void> _deleteReport(String filePath) async {
    await ProfileService.deleteMedicalReport(filePath);
    await _loadReports();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "View past medical\nreports",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: _uploadNewFiles,
                    icon: const Icon(Icons.add_circle, color: Color(0xFF21A658), size: 28),
                    tooltip: 'Upload new report',
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: reports.isEmpty
                  ? const Center(child: Text("No reports uploaded."))
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: reports.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        final isPdf = report is PdfMedicalReport;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => report.openDocument(),
                                child: Icon(
                                  isPdf ? Icons.picture_as_pdf : Icons.image,
                                  color: isPdf ? Colors.red : Colors.blue,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => report.openDocument(),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        report.fileName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        DateFormat('dd/MM/yyyy').format(report.dateAdded),
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Report'),
                                      content: const Text('Are you sure you want to delete this report?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteReport(report.filePath);
                                          },
                                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Delete report',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}