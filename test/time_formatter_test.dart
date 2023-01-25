import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:whats_json/src/helpers/date_formatter.dart';
import 'package:whats_json/src/helpers/time_formatter.dart';
import 'package:test/test.dart';

void main() async {
  await initializeDateFormatting();

  group("TimeFormatter valid strings", () {
    late TimeFormatter timeFormatter;

    setUp(() {
      // time formatter stores recognized time format and need to be reseted for tests
      timeFormatter = TimeFormatter();
    });

    test("#1: h:mm:ss a", () {
      final time = timeFormatter.parseString("21:59:00");
      expect(time, equals(DateTime.utc(1970, 1, 1, 21, 59).secondsSinceEpoch));

      // check the pattern is correct
      expect(timeFormatter.pattern, equals("h:mm:ss a"));
    });

    test("#2: h:mm a", () {
      final time = timeFormatter.parseString("4:25");
      expect(time, equals(DateTime.utc(1970, 1, 1, 4, 25).secondsSinceEpoch));
      expect(timeFormatter.pattern, equals("h:mm a"));
    });

    test("#3: h:mm a", () {
      final time = timeFormatter.parseString("04:25");
      expect(time, equals(DateTime.utc(1970, 1, 1, 4, 25).secondsSinceEpoch));
      expect(timeFormatter.pattern, equals("h:mm a"));
    });

    test("#4: h:mm a", () {
      final time = timeFormatter.parseString("04.25");
      expect(time, equals(DateTime.utc(1970, 1, 1, 4, 25).secondsSinceEpoch));
      expect(timeFormatter.pattern, equals("h:mm a"));
    });

    test("#5: h:mm a", () {
      final time = timeFormatter.parseString("04 25");
      expect(time, equals(DateTime.utc(1970, 1, 1, 4, 25).secondsSinceEpoch));
      expect(timeFormatter.pattern, equals("h:mm a"));
    });

    test("#5: Arabic", () {
      // There looks like a BUG in WhatsApp export algorithm for Arabic locale - seconds exported as 00 instead of 01 for same chat in Arabic and English
      final time = timeFormatter.parseString("٢:٥٦:٠٠ م");
      expect(time, equals(DateTime.utc(1970, 1, 1, 14, 56).secondsSinceEpoch));
      expect(timeFormatter.pattern, equals(DateFormat.Hms("ar").pattern));
    });
  });

  group("TimeFormatter invalid strings", () {
    late TimeFormatter timeFormatter;

    setUp(() {
      timeFormatter = TimeFormatter();
    });

    test("#1", () {
      final time = timeFormatter.parseString("21");
      expect(time, equals(0));
    });

    test("#2", () {
      final time = timeFormatter.parseString("21:");
      expect(time, equals(0));
    });

    test("#3", () {
      final time = timeFormatter.parseString("36:25");
      expect(time, equals(0));
    });

    test("#4", () {
      final time = timeFormatter.parseString(" 4:25");
      expect(time, equals(0));
    });
  });
}
