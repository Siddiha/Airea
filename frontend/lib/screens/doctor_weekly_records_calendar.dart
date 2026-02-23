import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'weekly_summary_detail_screen_new.dart';
import '../repositories/summary_repository.dart';
import '../config/api_config.dart';

class DoctorWeeklyRecordsCalendar extends StatefulWidget {
  const DoctorWeeklyRecordsCalendar({super.key});

  @override
  State<DoctorWeeklyRecordsCalendar> createState() => _DoctorWeeklyRecordsCalendarState();
}

class _DoctorWeeklyRecordsCalendarState extends State<DoctorWeeklyRecordsCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  
  void _selectWeek(DateTime selectedDate) {
    final int daysToSubtract = selectedDate.weekday - 1;
    final DateTime startOfWeek = selectedDate.subtract(Duration(days: daysToSubtract));
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    setState(() {
      _focusedDay = selectedDate;
      _rangeStart = startOfWeek;
      _rangeEnd = endOfWeek;
    });

    // Navigate to new weekly summary detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeeklySummaryDetailScreenNew(
          weekStart: startOfWeek,
          deviceId: ApiConfig.defaultDeviceId,
          repository: ApiSummaryRepository(),
        ),
      ),
    );
  }

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
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2FBF9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          
                          // Range Configuration
                          rangeStartDay: _rangeStart,
                          rangeEndDay: _rangeEnd,
                          rangeSelectionMode: RangeSelectionMode.toggledOn,
                          
                          // Handle Tap
                          onDaySelected: (selectedDay, focusedDay) {
                            _selectWeek(selectedDay);
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },

                          // Styles
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            leftChevronIcon: Icon(Icons.arrow_back, color: Colors.black87, size: 26),
                            rightChevronIcon: Icon(Icons.arrow_forward, color: Colors.black87, size: 26),
                          ),
                          
                          calendarStyle: const CalendarStyle(
                            rangeHighlightColor: Color(0xFFA8E6CF), 
                            
                            rangeStartDecoration: BoxDecoration(
                              color: Color(0xFFA8E6CF),
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                            ),
                            rangeEndDecoration: BoxDecoration(
                              color: Color(0xFFA8E6CF),
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            
                            rangeStartTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            rangeEndTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            withinRangeTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            
                            todayDecoration: BoxDecoration(
                              color: Color(0xFFE0F2F1),
                              shape: BoxShape.circle,
                            ),
                            todayTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                          
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                            weekendStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
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