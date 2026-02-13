import 'package:flutter/material.dart';

class DoctorWeeklyRecordsCalendar extends StatefulWidget {
  const DoctorWeeklyRecordsCalendar({super.key});

  @override
  State<DoctorWeeklyRecordsCalendar> createState() => _DoctorWeeklyRecordsCalendarState();
}

class _DoctorWeeklyRecordsCalendarState extends State<DoctorWeeklyRecordsCalendar> {
  final int _startDay = 15;
  final int _endDay = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. Top Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Weekly Summary',
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

            // --- 2. Scrollable Content ---
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        "Select a date range from the calendar",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
            
                      // --- CALENDAR CARD ---
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
                                  Icon(Icons.arrow_back, color: Colors.black87, size: 26),
                                  Text(
                                    "November",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward, color: Colors.black87, size: 26),
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
                                          color: Colors.black87, 
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
                                crossAxisSpacing: 0, 
                              ),
                              itemBuilder: (context, index) {
                                final day = index + 1;
                                
                                // Logic for the green range bar
                                final bool isInRange = day >= _startDay && day <= _endDay;
                                
                                return Container(
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.symmetric(vertical: 4), 
                                  decoration: BoxDecoration(
                                    color: isInRange ? const Color(0xFFA8E6CF).withOpacity(0.6) : Colors.transparent,
                                    borderRadius: BorderRadius.horizontal(
                                      left: day == _startDay ? const Radius.circular(8) : Radius.zero,
                                      right: day == _endDay ? const Radius.circular(8) : Radius.zero,
                                    ),
                                  ),
                                  child: Text(
                                    "$day",
                                    style: TextStyle(
                                      color: isInRange ? Colors.black : Colors.grey,
                                      fontWeight: isInRange ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 16,
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