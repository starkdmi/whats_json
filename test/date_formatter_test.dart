import 'dart:collection';

import 'package:whats_json/src/helpers/date_formatter.dart';
import 'package:test/test.dart';
import 'package:whats_json/src/models/message.dart';

void main() {
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
