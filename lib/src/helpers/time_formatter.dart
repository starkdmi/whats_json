import 'package:intl/intl.dart';
import 'date_formatter.dart';

/// Time formats
final List<DateFormat> timeFormats = [
  DateFormat.jms(),
  DateFormat.Hms(),
  DateFormat.jm(),
  DateFormat.Hm()
];

/// Class for work with time strings
class TimeFormatter {
  /// Active time format used to parse time strings
  DateFormat? _timeFormat;

  /// Indicates whenerver time string should be proceed in RTL Arabic format
  bool _isArabicRTL = false;

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
        } catch (_) {}
      }

      // Arabic RTL time
      try {
        final format = DateFormat.Hms("ar");
        var time = format.parse(string, true);

        // save pattern
        _timeFormat = format;
        _isArabicRTL = true;

        var seconds = time.secondsSinceEpoch;
        // fix 12 hour format
        if (string.endsWith("م")) {
          // PM
          seconds += const Duration(hours: 12).inSeconds;
        }
        return seconds;
      } catch (_) {}

      // failed to get format
      if (_timeFormat == null) return 0;
    }

    // if format is known - try to use it to get date
    try {
      DateTime dateTime;
      if (_isArabicRTL) {
        dateTime = _timeFormat!.parse(string, true);
      } else {
        dateTime = _timeFormat!.parseLoose(string, true);
      }
      return dateTime.secondsSinceEpoch;
    } catch (_) {
      return 0;
    }
  }

  /// Process time string, return values in seconds
  int parseString(String string) {
    string = string
        .replaceAll("a.m.", "am")
        .replaceAll("p.m.", "pm")
        .replaceAll("in the morning", "am")
        .replaceAll("in the afternoon", "pm")
        // to support formats with time like 00.00.00 (from unknown source)
        .replaceAll(".", ":");

    return _getTime(string);
  }
}
