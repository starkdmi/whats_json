import 'dart:collection';

import 'package:intl/date_symbol_data_local.dart';
import 'package:whats_json/src/helpers/date_formatter.dart';
import 'package:test/test.dart';
import 'package:whats_json/src/models/message.dart';

void main() async {
  await initializeDateFormatting();

  group("DateFormatter valid dates", () {
    late DateFormatter dateFormatter;

    setUp(() {
      // date formatter store recognized date format and need to be reseted for tests
      dateFormatter = DateFormatter();
    });

    test("#1: d-M-yyyy", () {
      var seconds = dateFormatter.parseString("22-03-1982", skipChecks: true);
      expect(seconds, equals(DateTime.utc(1982, 3, 22).secondsSinceEpoch));

      // check the pattern is correct
      expect(dateFormatter.pattern, equals("d-M-yyyy"));
    });

    test("#2: yyyy-M-d", () {
      var seconds = dateFormatter.parseString("2022-03-19", skipChecks: true);
      expect(seconds, equals(DateTime.utc(2022, 3, 19).secondsSinceEpoch));
      expect(dateFormatter.pattern, equals("yyyy-M-d"));
    });

    test("#3: d-M-yyyy (short year)", () {
      var seconds = dateFormatter.parseString("22-03-19", skipChecks: true);
      expect(seconds, equals(DateTime.utc(2019, 3, 22).secondsSinceEpoch));
      expect(dateFormatter.pattern, equals("d-M-yyyy"));
    });

    test("#4: d.M.yyyy", () {
      var seconds = dateFormatter.parseString("22.03.1981", skipChecks: true);
      expect(seconds, equals(DateTime.utc(1981, 3, 22).secondsSinceEpoch));
      expect(dateFormatter.pattern, equals("d.M.yyyy"));
    });

    test("#5: d M yyyy", () {
      var seconds = dateFormatter.parseString("22 03 1981", skipChecks: true);
      expect(seconds, equals(DateTime.utc(1981, 3, 22).secondsSinceEpoch));
      expect(dateFormatter.pattern,
          equals("d/M/yyyy")); // DateFormat.parseLoose is used
    });

    test("#6: M/d/yyyy", () {
      var seconds = dateFormatter.parseString("7/4/18", skipChecks: true);
      expect(seconds, equals(DateTime.utc(2018, 7, 4).secondsSinceEpoch));
      expect(dateFormatter.pattern, equals("M/d/yyyy"));
    });

    test("#7: yyyy/M/d", () {
      var seconds = dateFormatter.parseString("2022/10/25", skipChecks: true);
      expect(seconds, equals(DateTime.utc(2022, 10, 25).secondsSinceEpoch));
      expect(dateFormatter.pattern, equals("yyyy/M/d"));
    });

    test("#8: yyyy.M.d", () {
      var seconds = dateFormatter.parseString("2021.03.15", skipChecks: true);
      expect(seconds, equals(DateTime.utc(2021, 3, 15).secondsSinceEpoch));
      expect(dateFormatter.pattern, equals("yyyy.M.d"));
    });
  });

  group("DateFormatter localized dates", () {
    late DateFormatter dateFormatter;

    setUp(() {
      // date formatter store recognized date format and need to be reseted for tests
      dateFormatter = DateFormatter();
    });

    test("#1: EEEE, d MMMM yyyy (EN)", () {
      var seconds = dateFormatter.parseString("Wednesday, 07 March 2018", skipChecks: true);
      expect(seconds, equals(DateTime.utc(2018, 3, 7).secondsSinceEpoch));
      expect(dateFormatter.pattern, equals("EEEE, d MMMM yyyy"));
    });

    test("#2: EEEE, d MMMM yyyy (RU)", () {
      var seconds = dateFormatter.parseString("Вторник, 22 Марта 2022", skipChecks: true);
      expect(seconds, equals(DateTime.utc(2022, 3, 22).secondsSinceEpoch));
      expect(dateFormatter.pattern, equals("EEEE, d MMMM yyyy"));
    });

    test("#3: MMMM d yyyy (year missing)", () {
      var seconds = dateFormatter.parseString("March 8", skipChecks: true);
      expect(seconds, equals(DateTime.utc(DateTime.now().year, 3, 8).secondsSinceEpoch));
      expect(dateFormatter.pattern, equals("MMMM d yyyy"));
    });

    test("#4: d MMMM yyyy (year missing)", () {
      var seconds = dateFormatter.parseString("25 August", skipChecks: true);
      expect(seconds, equals(DateTime.utc(DateTime.now().year, 8, 25).secondsSinceEpoch));
      expect(dateFormatter.pattern, equals("d MMMM yyyy"));
    });

    test("#5: MMMM d yyyy", () {
      var seconds = dateFormatter.parseString("April 5 2022", skipChecks: true);
      expect(seconds, equals(DateTime.utc(2022, 4, 5).secondsSinceEpoch));
      expect(dateFormatter.pattern, equals("MMMM d yyyy"));
    });

    test("#6: yyyy MMMM d", () {
      var seconds = dateFormatter.parseString("2022 August 20", skipChecks: true);
      expect(seconds, equals(DateTime.utc(2022, 8, 20).secondsSinceEpoch));
      expect(dateFormatter.pattern, equals("yyyy MMMM d"));
    });

    test("#7: d MMMM yyyy", () {
      var seconds = dateFormatter.parseString("28 Aug 2013", skipChecks: true);
      expect(seconds, equals(DateTime.utc(2013, 8, 28).secondsSinceEpoch));
      expect(dateFormatter.pattern, equals("d MMMM yyyy"));
    });
  });

  group("DateFormatter alternative calendars", () {
    late DateFormatter dateFormatter;

    setUp(() {
      // date formatter store recognized date format and need to be reseted for tests
      dateFormatter = DateFormatter();
    });

    test("Japanese", () {
      var seconds = dateFormatter.parseString("3/18/R4", skipChecks: true);
      expect(seconds, equals(DateTime.utc(2022, 3, 18).secondsSinceEpoch));
      expect(dateFormatter.pattern, isNull);
      expect(dateFormatter.calendar, equals(Calendar.japanese));
    });

    test("Buddhist", () {
      var seconds = dateFormatter.parseString("3/18/2565 BE", skipChecks: true);
      expect(seconds, equals(DateTime.utc(2022, 3, 18).secondsSinceEpoch));
      expect(dateFormatter.pattern, isNull);
      expect(dateFormatter.calendar, equals(Calendar.buddhist));
    });
  });

  group("DateFormatter invalid dates", () {
    late DateFormatter dateFormatter;

    setUp(() {
      dateFormatter = DateFormatter();
    });

    test("#1", () {
      var seconds = dateFormatter.parseString("22.03-1981", skipChecks: true);
      expect(seconds, equals(0),
          reason: "Different separators are not allowed");
    });

    test("#2", () {
      var seconds =
          dateFormatter.parseString("Tomorrow 14.30", skipChecks: true);
      expect(seconds, equals(0));
    });

    test("#3", () {
      var seconds =
          dateFormatter.parseString("**August 12:15 PM ", skipChecks: true);
      expect(seconds, equals(0));
    });
  });

  group("DateFormatter fix dates", () {
    late DateFormatter dateFormatter;

    setUp(() {
      dateFormatter = DateFormatter();
    });

    test("Fix incorrect dates", () {
      // parse M/d/y string
      dateFormatter.parseString("04/20/22");

      // then parse d/M/y string
      dateFormatter.parseString("20/04/22");
      // right here shouldFix was switched to true

      final messages = Queue<Message>();
      messages.addAll([
        // d/M/y formated date string
        Message(
            type: "text",
            content: "Hello World",
            dateString: "21/04/22",
            timeString: "12:59")
          ..dateTime = 0 // indicates invalid dates
          ..time = 46740 // 12:59 in seconds
      ]);
      dateFormatter.fixDates(messages);

      expect(messages.first.dateTime,
          equals(DateTime.utc(2022, 4, 21, 12, 59).secondsSinceEpoch));
    });
  });
}
