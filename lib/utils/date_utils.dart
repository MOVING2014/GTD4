import 'package:intl/intl.dart';

class AppDateUtils {
  // Format a date to a human-readable string
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == tomorrow) {
      return 'Tomorrow';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return DateFormat.MMMMd().format(date); // e.g., "June 15"
    } else {
      return DateFormat.yMMMMd().format(date); // e.g., "June 15, 2023"
    }
  }

  // Format a time to a human-readable string
  static String formatTime(DateTime time) {
    return DateFormat.jm().format(time); // e.g., "2:30 PM"
  }

  // Format a date and time to a human-readable string
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} at ${formatTime(dateTime)}';
  }

  // Get the first day of the week containing the given date
  static DateTime getFirstDayOfWeek(DateTime date) {
    final day = date.weekday;
    return date.subtract(Duration(days: day - 1));
  }

  // Get the last day of the week containing the given date
  static DateTime getLastDayOfWeek(DateTime date) {
    final day = date.weekday;
    return date.add(Duration(days: 7 - day));
  }

  // Get a list of dates for a week
  static List<DateTime> getDaysInWeek(DateTime date) {
    final first = getFirstDayOfWeek(date);
    return List.generate(
      7,
      (index) => DateTime(
        first.year,
        first.month,
        first.day + index,
      ),
    );
  }
  
  // Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  // Check if a date is in the future
  static bool isFuture(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    return dateToCheck.isAfter(today);
  }
  
  // Check if a date is in the past
  static bool isPast(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    return dateToCheck.isBefore(today);
  }
} 