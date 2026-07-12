import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  return DateFormat('EEE, dd MMM').format(date);
}

String formatTime(DateTime date) {
  return DateFormat('hh:mm a').format(date);
}
