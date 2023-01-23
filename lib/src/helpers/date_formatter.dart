import 'dart:collection';
import 'package:intl/intl.dart';
import '../models/message.dart';

/// Date formats
/// Additional format specified for locale available at https://github.com/dart-lang/intl/tree/master/lib/src/data/dates/symbols/es.json in DATEFORMATS
final List<DateFormat> dateFormats = [
  DateFormat("M/d/yyyy"),
  DateFormat("d/M/yyyy"),
  DateFormat("yyyy/M/d"),
  DateFormat("d.M.yyyy"),
  DateFormat("d-M-yyyy"),
  DateFormat("yyyy-M-d"),
  DateFormat("yyyy.M.d"),
];
// Localized dates are not captured by regular expressions now (!)
/*final List<DateFormat Function(String)> localizedDateFormats = [
  (String locale) => DateFormat("d MMMM yyyy", locale),
  (String locale) => DateFormat("MMMM d yyyy", locale),
  (String locale) => DateFormat("yyyy MMMM d", locale),
  (String locale) => DateFormat("E, d MMM yyyy", locale), 
  (String locale) => DateFormat("EEEE, d MMMM yyyy", locale),
];*/

/// WhatsApp dates has no milliseconds data - all dates stored in seconds since 1970
extension SecondsSinceEpoch on DateTime {
  int get secondsSinceEpoch => millisecondsSinceEpoch ~/ 1000;
}

/// Class for working with string dates
class DateFormatter {
  /// Active date format used to parse date strings
  DateFormat? _dateFormat;

  /// Variables required to control the date formatting correctness
  int _previousDate = 0; // in seconds
  bool shouldFix = false;

  /// Current date format as string
  String? get pattern => _dateFormat?.pattern;

  /// Try to get date from [dateString] using [format]
  DateTime? _parse(DateFormat format, String dateString) {
    // return format.parse(dateString); // parseLoose, parseStrict
    try {
      var dateTime = format.parseLoose(dateString, true);
      if (dateTime.year >= 0 && dateTime.year < 100) { // two digits year format
        dateTime = DateTime.utc(dateTime.year + 2000, dateTime.month, dateTime.day);
      }
      return dateTime;
    } catch (_) { return null; }
  }

  /// Convert string date to seconds since epoch
  /// Zero returned on failure
  int _getDate(String string) {
    // do not process date if pattern is invalid
    if (shouldFix) return 0; 

    if (_dateFormat == null) {    

      // Simple date format
      for (final format in dateFormats) { 
        try {
          final dateTime = _parse(format, string);
          // print(dateTime);
          // print(format.pattern);
          if (dateTime != null) {
            // save pattern
            _dateFormat = format;
            return dateTime.secondsSinceEpoch;
          }
        } catch(_) { }
      }

      // Localized date format - skipped for now and not even captured by date regex (!)
      /*if (_dateFormat == null) {
        final locales = DateFormat.allLocalesWithSymbols();
        for (var format in localizedDateFormats) {
          for (final locale in locales) {      
            try {
              final localizedFormat = format(locale);
              // localizedFormat.parse(dateString);
              final dateTime = _parse(localizedFormat, string);
              if (dateTime != null) {
                // save pattern
                _dateFormat = localizedFormat;
                return dateTime.secondsSinceEpoch;
              }
            } catch(_) { }
          }
        }
      }*/

      // TODO: try Japanese calendar - 3/18/R4
      /*if (_dateFormat == null) {
        for (final monthThanDate in [true, false]) {
          for (final separator in ["/", "-", "."]) {
            final date = parseJapaneseDate(dateString, separator: separator, monthThanDate: monthThanDate);
            if (date != null) {
              // save separator, monthThanDate and date 
            }
          }
        }
      }*/

      // TODO: try Buddhist calendar - 3/18/2565 BE
      // if (_dateFormat == null) { Buddhist ... }
      // for Buddhist calendar buddhist_datetime_dateformat dart package may be used

      // TODO: Arabic RTL date supports by intl package
      // if (_dateFormat == null) { RTL ... }
      /*await initializeDateFormatting('ar');
      const dateTimeString = "١٨‏/٣‏/٢٠٢٢، ٢:٥٦:٠٠ م";
      final dateFormatArabic = DateFormat.yMd("ar"); 
      final date = dateFormatArabic.parse(dateTimeString);*/

      // failed to get format
      if (_dateFormat == null) return 0; 
    }

    final dateTime = _parse(_dateFormat!, string);
    if (dateTime == null) return 0; // failed to apply the pattern, will be fixed in fix() after all messages are proceed

    return dateTime.secondsSinceEpoch;
  }

  /// Process date string, return values in seconds, additionally checks if dates are increasing
  int parseString(String string, { skipChecks = false }) {
    // Language words in Intl for different locales are lowercased
    // string = string.toLowerCase();

    final date = _getDate(string);

    // check if dates values are increasing over messages - otherwise wrong pattern used
    if (!skipChecks && !shouldFix) {
      if (date == 0 || (date + 1 < _previousDate)) { // allow 1 second difference
        shouldFix = true;
      }
      _previousDate = date;
    }

    return date;
  }

  /// [fixDates] helper function
  /// This function looks for date format which will work for every existing message
  bool _fix(Queue<Message> messages) {
    print("Wrong Format: ${_dateFormat?.pattern}");

    bool succeedAll(DateFormat format) {
      for (final message in messages) {
        final date = _parse(format, message.dateString);

        if (date == null) return false;
        message.dateTime = date.secondsSinceEpoch + (message.time ?? 0);
      }
      return true;
    }

    // Simple date format
    for (final format in dateFormats) { 
      if (succeedAll(format)) {
        // quit
        // print("Fixed: ${format.pattern}");
        _dateFormat = format;
        return true;
      }
    }

    // Localized date format
    /*final locales = DateFormat.allLocalesWithSymbols();
    for (var format in localizedDateFormats) {
      for (final locale in locales) {    
        final localizedFormat = format(locale);  
        if (succeedAll(localizedFormat)) {
          // quit
          _dateFormat = localizedFormat;
          return true;
        }
      }
    }*/

    // Japanese, Buddhist and Arabic RTL ...

    // format not found
    return false;
  }

  /// Fix date format for all messages 
  /// Sometimes d/M/y can be recognized as M/d/y - 04/06/2022
  void fixDates(Queue<Message> messages) {
    bool fixed;
    if (messages.isNotEmpty && shouldFix) {
      fixed = _fix(messages);
    } else {
      fixed = true;
    }
    if (fixed) {
      // fixed 
      for (final message in messages) {
        message.dateString = "";
        message.timeString = "";
      }
    } else {
      // date format unknown - do not remove original date and time strings
      for (final message in messages) {
        message.dateTime = 0;
      }
    }
  }
}