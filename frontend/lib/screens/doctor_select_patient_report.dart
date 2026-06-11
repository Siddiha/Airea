import 'package:flutter/material.dart';
import 'doctor_patient_report_detail.dart';

class DoctorSelectPatientReport extends StatelessWidget {
  const DoctorSelectPatientReport({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'View past medical reports',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // --- List of Reports ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  _buildReportCard(
                    context: context,
                    fileName: "Report 1",
                    dateAdded: "12/12/2025",
                  ),
                  const SizedBox(height: 16),
                  _buildReportCard(
                    context: context,
                    fileName: "Report 2",
                    dateAdded: "12/12/2025",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // --- Bottom Navigation Bar ---
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home_filled,
              label: "Home",
              isSelected: false,
              onTap: () {
              },
            ),
            _buildNavItem(
              icon: Icons.menu_book_outlined,
              label: "Trends &\nsummary",
              isSelected: true,
              onTap: () {
                 
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({required BuildContext context, required String fileName, required String dateAdded}) {
    return GestureDetector(
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorPatientReportDetail(
              fileName: fileName,
            ),
          ),
        );
      },
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBF9), 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Custom PDF Icon
          Container(
            width: 50,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Expanded(
                   child: Icon(Icons.picture_as_pdf_outlined, color: Colors.red, size: 30)
                ),
                Container(
                  width: double.infinity,
                  color: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: const Text(
                    "PDF",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 20),
          
          // File Details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "File name",
                style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              Text(
                fileName,
                style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Date added",
                style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              Text(
                dateAdded,
                style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.black : Colors.grey,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.black : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}