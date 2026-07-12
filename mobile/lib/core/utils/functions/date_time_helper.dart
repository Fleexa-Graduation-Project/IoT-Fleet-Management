class DateTimeHelper {
  /// Smart time formatting function that returns a human-readable string based on the provided [dateTime].
  /// It handles various cases such as "Just now", "X min ago", "Today", "Yesterday", and older dates with month and day formatting.

  static String formatDynamicTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    int hour = dateTime.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String exactTime = '$hour:$minute $period';

    // 1. if the difference is less than 1 minute, return "Just now"
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    // 2. if the date is today or yesterday or older
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (targetDate == today) {
      return 'Today, $exactTime';
    } else if (targetDate == yesterday) {
      return 'Yesterday, $exactTime';
    } else {
      // if the date is older than yesterday, return the month and day with the exact time
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      String monthName = months[dateTime.month - 1];
      return '$monthName ${dateTime.day}, $exactTime';
    }
  }
}
