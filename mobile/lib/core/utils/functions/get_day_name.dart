import 'package:intl/intl.dart';

String getDayName(String shortDate) {
  try {
    // shortDate like "Jan 01" or "Feb 14"
    // we add the current year to make it a complete date
    int year = DateTime.now().year;

    // we parse the date string into a DateTime object
    DateTime parsedDate = DateFormat('MMM dd yyyy').parse('$shortDate $year');

    // we request it to return the abbreviated day name (Mon, Tue, Wed)
    return DateFormat('E').format(parsedDate);
  } catch (e) {
    // if there's any error in the conversion, display the date as is
    return shortDate;
  }
}
