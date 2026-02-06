import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Adjust import to match your folder structure
import '../models/medical_report_model.dart';

class ViewReportsScreen extends StatefulWidget {
  const ViewReportsScreen({Key? key}) : super(key: key);

  @override
  State<ViewReportsScreen> createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  final MedicalReportService _reportService = MedicalReportService();
  late List<MedicalDocument> reports;

  @override
  void initState() {
    super.initState();
    reports = _reportService.reports;
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
                        
                        return GestureDetector(
                          onTap: () => report.openDocument(), // Polymorphic call
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isPdf ? Icons.picture_as_pdf : Icons.image,
                                  color: isPdf ? Colors.red : Colors.blue,
                                  size: 40,
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(report.fileName, 
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1, 
                                        overflow: TextOverflow.ellipsis
                                      ),
                                      Text(
                                        DateFormat('dd/MM/yyyy').format(report.dateAdded),
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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