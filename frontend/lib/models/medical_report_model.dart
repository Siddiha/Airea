import 'package:open_filex/open_filex.dart';

abstract class MedicalDocument {
  final String id;
  final String fileName;
  final DateTime dateAdded;
  final String _filePath;

  MedicalDocument({
    required this.id,
    required this.fileName,
    required this.dateAdded,
    required String filePath,
  }) : _filePath = filePath;

  String get filePath => _filePath;

  Future<OpenResult> openDocument();
}

class PdfMedicalReport extends MedicalDocument {
  PdfMedicalReport({
    required String id,
    required String fileName,
    required DateTime dateAdded,
    required String filePath,
  }) : super(id: id, fileName: fileName, dateAdded: dateAdded, filePath: filePath);

  @override
  Future<OpenResult> openDocument() async {
    print("Opening PDF: $fileName");
    // Explicitly opening as PDF
    return await OpenFilex.open(_filePath, type: "application/pdf");
  }
}

class ImageMedicalReport extends MedicalDocument {
  ImageMedicalReport({
    required String id,
    required String fileName,
    required DateTime dateAdded,
    required String filePath,
  }) : super(id: id, fileName: fileName, dateAdded: dateAdded, filePath: filePath);

  @override
  Future<OpenResult> openDocument() async {
    print("Opening Image: $fileName");
    // Let system auto-detect image type
    return await OpenFilex.open(_filePath);
  }
}

// store the file data
class MedicalReportService {
  // Singleton pattern to share data between screens
  static final MedicalReportService _instance = MedicalReportService._internal();

  factory MedicalReportService() {
    return _instance;
  }

  MedicalReportService._internal();

  final List<MedicalDocument> _reports = [];

  List<MedicalDocument> get reports => List.unmodifiable(_reports);

  void addReport(MedicalDocument report) {
    _reports.add(report);
  }
}