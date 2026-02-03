import 'package:flutter/material.dart';
import '../config/app_theme.dart';

enum CalendarMode { singleDate, weekRange }

class CustomCalendarWidget extends StatefulWidget {
  final CalendarMode mode;
  final Function(DateTime)? onDateSelected;
  final Function(DateTime, DateTime)? onWeekSelected;
  final DateTime? initialMonth;

  const CustomCalendarWidget({
    super.key,
    required this.mode,
    this.onDateSelected,
    this.onWeekSelected,
    this.initialMonth,
  });

  @override
  State<CustomCalendarWidget> createState() => _CustomCalendarWidgetState();
}

class _CustomCalendarWidgetState extends State<CustomCalendarWidget> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;
  DateTime? _selectedWeekStart;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialMonth ?? DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  List<DateTime?> _getDaysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;

    // Get the weekday of the first day (1 = Monday, 7 = Sunday)
    final firstWeekday = firstDay.weekday;

    final days = <DateTime?>[];

    // Add empty slots for days before the 1st
    for (int i = 1; i < firstWeekday; i++) {
      days.add(null);
    }

    // Add all days of the month
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }

    return days;
  }

  void _onDateTap(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    widget.onDateSelected?.call(date);
  }

  void _onWeekTap(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    setState(() {
      _selectedWeekStart = weekStart;
    });
    widget.onWeekSelected?.call(weekStart, weekEnd);
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  bool _isInSelectedWeek(DateTime date) {
    if (_selectedWeekStart == null) return false;
    final weekEnd = _selectedWeekStart!.add(const Duration(days: 6));
    return date.isAfter(_selectedWeekStart!.subtract(const Duration(days: 1))) &&
           date.isBefore(weekEnd.add(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    final monthName = _getMonthName(_currentMonth.month);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousMonth,
              ),
              Text(
                monthName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),

        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((day) => SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),

        const SizedBox(height: 8),

        // Calendar grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildCalendarGrid(days),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(List<DateTime?> days) {
    final rows = <Widget>[];
    for (int i = 0; i < days.length; i += 7) {
      final weekDays = days.sublist(i, i + 7 > days.length ? days.length : i + 7);
      
      if (widget.mode == CalendarMode.weekRange && weekDays.any((d) => d != null)) {
        final firstNonNull = weekDays.firstWhere((d) => d != null, orElse: () => null);
        if (firstNonNull != null) {
          rows.add(_buildWeekRow(weekDays, _getWeekStart(firstNonNull)));
        } else {
          rows.add(_buildDayRow(weekDays));
        }
      } else {
        rows.add(_buildDayRow(weekDays));
      }
    }
    return Column(children: rows);
  }

  Widget _buildDayRow(List<DateTime?> weekDays) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDays.map((date) {
          if (date == null) {
            return const SizedBox(width: 40, height: 40);
          }
          
          final isSelected = _selectedDate != null &&
              date.day == _selectedDate!.day &&
              date.month == _selectedDate!.month &&
              date.year == _selectedDate!.year;

          return InkWell(
            onTap: () => _onDateTap(date),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeekRow(List<DateTime?> weekDays, DateTime weekStart) {
    final isSelectedWeek = _selectedWeekStart != null &&
        weekStart.isAtSameMomentAs(_selectedWeekStart!);

    return InkWell(
      onTap: () => _onWeekTap(weekStart),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelectedWeek
              ? AppTheme.primaryTeal.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays.map((date) {
            if (date == null) {
              return const SizedBox(width: 40, height: 32);
            }

            return Container(
              width: 40,
              height: 32,
              decoration: BoxDecoration(
                color: isSelectedWeek
                    ? AppTheme.primaryTeal
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelectedWeek ? Colors.white : Colors.black87,
                    fontWeight: isSelectedWeek ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
