import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; 
import '../config/app_theme.dart'; 
import 'doctor_daily_summary_detail.dart';

class DoctorDailyRecordsCalendar extends StatefulWidget {
  const DoctorDailyRecordsCalendar({super.key});

  @override
  State<DoctorDailyRecordsCalendar> createState() => _DoctorDailyRecordsCalendarState();
}

class _DoctorDailyRecordsCalendarState extends State<DoctorDailyRecordsCalendar> {
  // 1. Add these variables to track the date
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // Default selection is today
  }

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
                        "Select a date from the calendar",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- CALENDAR CARD (Replaced Manual Grid with TableCalendar) ---
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2FBF9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: TableCalendar(
                          // 2. Basic Setup
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          
                          // 3. Selection Logic
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay; 
                            });
                            
                            // Navigate to detail screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DoctorDailySummaryDetail(
                                  day: selectedDay.day, 
                                ),
                              ),
                            );
                          },
                          
                          // 4. Update the month when arrows are clicked
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },

                          // 5. Styles to match your design
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false, // Hides the "2 weeks" toggle
                            titleCentered: true,
                            titleTextStyle: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey, // Matches your "November" color
                            ),
                            leftChevronIcon: Icon(Icons.arrow_back, color: Colors.grey, size: 26),
                            rightChevronIcon: Icon(Icons.arrow_forward, color: Colors.grey, size: 26),
                          ),
                          calendarStyle: const CalendarStyle(
                            // Selected day style (Green Circle)
                            selectedDecoration: BoxDecoration(
                              color: Color(0xFFA8E6CF),
                              shape: BoxShape.circle,
                            ),
                            selectedTextStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            // Today style
                            todayDecoration: BoxDecoration(
                              color: Color(0xFFE0F2F1), // Lighter green for today
                              shape: BoxShape.circle,
                            ),
                            todayTextStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            defaultTextStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                            weekendTextStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                            weekendStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
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
          ),
        ),
      ],
    );
  }
}