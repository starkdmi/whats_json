import 'package:intl/intl.dart';
import 'package:whats_json/src/date_formatter.dart';

/// Time formats
final List<DateFormat> timeFormats = [
  DateFormat.jms(), DateFormat.Hms(), 
  DateFormat.jm(), DateFormat.Hm()
];

/// Class for work with time strings
class TimeFormatter {
  /// Active time format used to parse time strings
  DateFormat? _timeFormat;

  /// Current time format as string
  String? get pattern => _timeFormat?.pattern;

  /// Convert time string to seconds since epoch
  /// Zero returned on failure
  int _getTime(String string) {
    if (_timeFormat == null) {
      // loop over predefined formats
      for (final format in timeFormats) {
        try {
          final dateTime = format.parseLoose(string, true); // parse
          // save pattern
          _timeFormat = format;
          return dateTime.secondsSinceEpoch;
        } catch(_) { }
      }

      // Arabic RTL
      /*await initializeDateFormatting('ar');
      const timeString = "٢:٥٦:٠٠ م";
      final timeFormatArabic = DateFormat.Hms("ar"); 
      final time = dateFormatArabic.parse(timeString);*/

      // failed to get format
      if (_timeFormat == null) return 0;
    }

    // if format is known - try to use it to get date
    try {
      final dateTime = _timeFormat!.parseLoose(string, true); // parse
      return dateTime.secondsSinceEpoch;
    } catch(_) { 
      return 0; 
    }
  }

  /// Process time string, return values in seconds
  int parseString(String string) {
    // to support formats with time like 00.00.00 (from unknown source)
    string = string.replaceAll("a.m.", "am").replaceAll("p.m.", "pm").replaceAll(".", ":");

    return _getTime(string);
  }
}