import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'doctor_daily_summary_detail.dart'; 

class DoctorDailyRecordsCalendar extends StatefulWidget {
  const DoctorDailyRecordsCalendar({super.key});

  @override
  State<DoctorDailyRecordsCalendar> createState() => _DoctorDailyRecordsCalendarState();
}

class _DoctorDailyRecordsCalendarState extends State<DoctorDailyRecordsCalendar> {
  int _selectedDay = 20; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: SafeArea(
        child: Column(
          children: [
            // --- Top Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daily Summary',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        "Select a date form the calendar",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
            
                      // --- CALENDAR CARD  ---
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 400), 
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2FBF9), 
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Month Header
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(Icons.arrow_back, color: Colors.grey, size: 26),
                                  Text(
                                    "November",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward, color: Colors.grey, size: 26),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Days of Week
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: ["M", "T", "W", "T", "F", "S", "S"]
                                  .map((day) => Text(
                                        day,
                                        style: const TextStyle(
                                          color: Colors.grey, 
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14
                                        ),
                                      ))
                                  .toList(),
                            ),
                            
                            const SizedBox(height: 10),
            
                            // Date Grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 30,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 1.3, 
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                              itemBuilder: (context, index) {
                                final day = index + 1;
                                final isSelected = day == _selectedDay;
                                
                                return GestureDetector(
                                  onTap: () {
                                    setState((){
                                      _selectedDay = day;
                                    });
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DoctorDailySummaryDetail(day: day),
                                      ),
                                      );
                              },
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFA8E6CF) : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      "$day",
                                      style: TextStyle(
                                        color: isSelected ? Colors.black : Colors.grey,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30), 
                    ],
                  ),
                ),
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
             _buildNavItem(Icons.home_filled, "Home", false),
             _buildNavItem(Icons.menu_book_outlined, "Trends &\nsummary", true),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isSelected ? Colors.black : Colors.grey, size: 28),
        const SizedBox(height: 4),
        Text(
          label, 
          textAlign: TextAlign.center, 
          style: TextStyle(
            fontSize: 10, 
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          )
        ),
      ],
    );
  }
}