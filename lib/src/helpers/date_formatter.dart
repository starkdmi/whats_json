import 'dart:collection';
import 'package:intl/intl.dart';
import '../models/message.dart';
import 'logger.dart';

/// Supported calendars
enum Calendar { gregorian, buddhist, japanese }

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
  /// Active calendar used for date parsing
  /// Dates proceed differently for each of calendars
  Calendar calendar = Calendar.gregorian;

  /// Indicates whenerver time string should be proceed in RTL Arabic format
  bool _isArabicRTL = false;

  /// Active date format used to parse date strings
  DateFormat? _dateFormat;

  /// Custom calendar specific properties
  Map<String, dynamic> fields = {};

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
      if (dateTime.year >= 0 && dateTime.year < 100) {
        // two digits year format
        dateTime =
            DateTime.utc(dateTime.year + 2000, dateTime.month, dateTime.day);
      }
      return dateTime;
    } catch (_) {
      return null;
    }
  }

  /// Convert string date to seconds since epoch
  /// Zero returned on failure
  int _getDate(String string) {
    // do not process date if pattern is invalid
    if (shouldFix) return 0;

    // remove hidden RTL characters
    var stringEscaped = string.replaceAll(RegExp("\u200F"), "");

    if (_dateFormat == null) {
      // Buddhist calendar - 3/18/2565 BE
      // Buddhist date proceed only in M/d/y and d/M/y formats
      if (string.endsWith(" BE")) {
        final buddhistDate =
            tryAlernativeCalendar(Calendar.buddhist, stringEscaped);
        if (buddhistDate != null) return buddhistDate;
      }

      // Simple date format
      for (final format in dateFormats) {
        try {
          final dateTime = _parse(format, stringEscaped);
          if (dateTime != null) {
            // save pattern
            calendar = Calendar.gregorian;
            _dateFormat = format;
            return dateTime.secondsSinceEpoch;
          }
        } catch (_) {}
      }

      // Localized date format - skipped for now and not even captured by date regex (!)
      /* final locales = DateFormat.allLocalesWithSymbols();
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
      }*/

      // Japanese calendar - 3/18/R4
      // Japanese date proceed only in M/d/y and d/M/y formats
      final japaneseDate =
          tryAlernativeCalendar(Calendar.japanese, stringEscaped);
      if (japaneseDate != null) return japaneseDate;

      // Arabic RTL date
      try {
        final format = DateFormat.yMd("ar");
        final arabicDate = format.parse(string, true);
        // save pattern
        calendar = Calendar.gregorian;
        _dateFormat = format;
        _isArabicRTL = true;
        return arabicDate.secondsSinceEpoch;
      } catch (error) {
        print(error);
      }

      // failed to get format
      if (_dateFormat == null) return 0;
    }

    DateTime? dateTime;
    switch (calendar) {
      case Calendar.gregorian:
        // for RTL we need to proceed original unescaped string
        if (_isArabicRTL) stringEscaped = string;

        dateTime = _parse(_dateFormat!, stringEscaped);
        break;
      case Calendar.buddhist:
        dateTime = parseBuddhistDate(stringEscaped,
            separator: fields["separator"],
            monthThanDate: fields["monthThanDate"]);
        break;
      case Calendar.japanese:
        dateTime = parseJapaneseDate(stringEscaped,
            separator: fields["separator"],
            monthThanDate: fields["monthThanDate"]);
        break;
    }

    if (dateTime == null)
      return 0; // failed to apply the pattern, will be fixed in fix() after all messages are proceed

    return dateTime.secondsSinceEpoch;
  }

  /// Process date string, return values in seconds, additionally checks if dates are increasing
  int parseString(String string, {skipChecks = false}) {
    // Language words in Intl for different locales are lowercased
    // string = string.toLowerCase();

    final date = _getDate(string);

    // check if dates values are increasing over messages - otherwise wrong pattern used
    if (!skipChecks && !shouldFix) {
      if (date == 0 || (date + 1 < _previousDate)) {
        // allow 1 second difference
        shouldFix = true;
      }
      _previousDate = date;
    }

    return date;
  }

  /// [fixDates] helper function
  /// This function looks for date format which will work for every existing message
  /// Warning: Japanese and Buddhist calendars as well as Arabic RTL are skipped
  bool _fix(Queue<Message> messages) {
    // TODO
    // Find which format better suit in percentage of valid dates
    // If not 100% then additionally save date and time strings

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

    // format not found
    return false;
  }

  /// Fix date format for all messages
  /// Sometimes d/M/y can be recognized as M/d/y - 04/06/2022
  void fixDates(Queue<Message> messages, {ParserLogger? logger}) {
    bool fixed;
    if (messages.isNotEmpty && shouldFix) {
      logger?.info("[Parser]: Date Format is incorrect ($pattern), fixing...");
      fixed = _fix(messages);
      if (fixed) logger?.info("[Parser]: Date Format fixed to $pattern");
    } else {
      fixed = true;
    }
    if (fixed) {
      // continue
      for (final message in messages) {
        message.dateString = "";
        message.timeString = "";
      }
    } else {
      // date format unknown - do not remove original date and time strings
      for (final message in messages) {
        message.dateTime = 0;
      }
      logger?.info(
          "[Parser]: Date Format in unknown, saving original date and time strings");
    }
  }

  /// Used for Japanese and Buddhist calendars tests
  int? tryAlernativeCalendar(Calendar calendar, String string) {
    for (final monthThanDate in [true, false]) {
      for (final separator in ["/", "-", "."]) {
        DateTime? date;

        switch (calendar) {
          case Calendar.japanese:
            date = parseJapaneseDate(string,
                separator: separator, monthThanDate: monthThanDate);
            break;
          case Calendar.buddhist:
            date = parseBuddhistDate(string,
                separator: separator, monthThanDate: monthThanDate);
            break;
          case Calendar.gregorian:
            return null;
        }

        if (date != null) {
          // save format info
          calendar = calendar;
          fields = {
            "separator": separator,
            "monthThanDate": monthThanDate,
          };

          return date.secondsSinceEpoch;
        }
      }
    }
    return null;
  }
}

/// Convert Japanese Imperial Calendar date to the Gregorian format
/// Since 1868 there have only been five era names assigned:
///   Meiji, Taishō, Shōwa, Heisei, and Reiwa
/// As WhatsApp app released in 2009 there is only two eras left:
///   Heisei (1989 - 2019) and Reiwa (2019 - Present)
///
/// Example: 3/18/R4 -> 2022-03-18
DateTime? parseJapaneseDate(String dateString,
    {String separator = "/", bool monthThanDate = true}) {
  final parts = dateString.split(separator);
  if (parts.length != 3) return null;

  // extract date and month
  DateTime date;
  try {
    date = DateFormat(monthThanDate ? "M${separator}d" : "d${separator}M")
        .parse("${parts[0]}$separator${parts[1]}", true);
  } catch (_) {
    return null;
  }

  // process era name
  int year;
  final era = parts[2]; // get era in format like R4 or H20
  if (era.startsWith("H")) {
    year = 1989; // starting point of Heisei era
  } else if (era.startsWith("R")) {
    year = 2019; // starting point of Reiwa era
  } else {
    return null;
  }

  // era number
  int? index = int.tryParse(era.substring(1));
  if (index == null) return null;

  return DateTime.utc(year + index - 1, date.month, date.day);
}

/// Convert Buddhist Calendar date to the Gregorian format
/// CE = BE - 543 years
DateTime? parseBuddhistDate(String dateString,
    {String separator = "/", bool monthThanDate = true}) {
  final string =
      dateString.substring(0, dateString.length - 3); // remove BE at the end
  final parts = string.split(separator);
  if (parts.length != 3) return null;

  // extract date and month
  DateTime date;
  try {
    date = DateFormat(monthThanDate ? "M${separator}d" : "d${separator}M")
        .parse("${parts[0]}$separator${parts[1]}", true);
  } catch (_) {
    return null;
  }

  int? year = int.tryParse(parts[2]);
  if (year == null) return null;

  return DateTime.utc(year - 543, date.month, date.day);
}
