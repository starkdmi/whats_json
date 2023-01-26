import 'package:whats_json/whats_json.dart';
import 'package:test/test.dart';

void main() {
  group("Regular message", () {
    final regex = RegExp(WhatsAppPatterns.universal, caseSensitive: false);

    test("#1", () {
      expectRegex(regex, "[3/27/22, 21:41:35] Elon Musk: Hello, Space",
          date: "3/27/22",
          time: "21:41:35",
          sender: "Elon Musk",
          content: "Hello, Space");
    });

    test("#2 Without brackets sender", () {
      expectRegex(regex, "3/27/22, 21:41:35 - Elon Musk: Hello, Space",
          date: "3/27/22",
          time: "21:41:35",
          sender: "Elon Musk",
          content: "Hello, Space");
    });

    test("#3 Multiline", () {
      expectRegex(regex, "[3/18/22, 14:56:01] Elon Musk: Some\nmultiline\ntext",
          date: "3/18/22",
          time: "14:56:01",
          sender: "Elon Musk",
          content: "Some\nmultiline\ntext");
    });

    test("#4 Invalid sender", () {
      final data = "[3/18/22, 14:56:01] :Elon Musk:: Hello, Space";
      final match = regex.firstMatch(data);
      expect(match, isNull, reason: "Sender cannot ends with `:` symbol");
    });
  });

  group("Regular message time first", () {
    final regex = RegExp(WhatsAppPatterns.timeFirst, caseSensitive: false);

    test("#1", () {
      expectRegex(regex, "[21:41:35, 3/27/22] Elon Musk: Hello, Space",
          date: "3/27/22",
          time: "21:41:35",
          sender: "Elon Musk",
          content: "Hello, Space");
    });
  });

  group("System message", () {
    final regex =
        RegExp(WhatsAppPatterns.systemUniversal, caseSensitive: false);

    test("#1", () {
      expectRegex(
          regex, "11/01/2023, 16:11 - Elon Musk created group \"Group Chat\"",
          date: "11/01/2023",
          time: "16:11",
          content: "Elon Musk created group \"Group Chat\"");
    });

    test("#2", () {
      expectRegex(
          regex, "11/01/2023, 16:15 - You changed the group description",
          date: "11/01/2023",
          time: "16:15",
          content: "You changed the group description");
    });

    test("System text", () {
      var isSystem = WhatsAppPatterns.isSystemMessageText(
          "Messages and calls are end-to-end encrypted. No one outside of this chat, not even WhatsApp, can read or listen to them.\n"); // iOS

      isSystem = WhatsAppPatterns.isSystemMessageText(
          "Messages and calls are end-to-end encrypted. No one outside of this chat, not even WhatsApp, can read or listen to them. Tap to learn more.\n"); // Android
      expect(isSystem, isTrue);

      isSystem = WhatsAppPatterns.isSystemMessageText("Hello there");
      expect(isSystem, isFalse);
    });
  });

  group("Date", () {
    final regex = RegExp(WhatsAppPatterns.date, caseSensitive: false);

    test("Date first", () {
      final data = "[11/01/2023,";
      final match = regex.firstMatch(data);
      expect(match?.namedGroup("date"), equals("11/01/2023"));
    });

    test("Time first", () {
      final data = "21:46, 11/01/2023]";
      final match = regex.firstMatch(data);
      expect(match?.namedGroup("date"), equals("11/01/2023"));
    });

    test("Time first with space as separator", () {
      final data = "21:46 11/01/2023";
      final match = regex.firstMatch(data);
      expect(match?.namedGroup("date"), equals("11/01/2023"));
    });

    test("Date time with space as separator", () {
      final data = "[11/01/2023 21:20:15]";
      final match = regex.firstMatch(data);
      expect(match?.namedGroup("date"), equals("11/01/2023"));
    });
  });

  group("Localized dates", () {
    final regex = RegExp(WhatsAppPatterns.localeDate,
        caseSensitive: false, unicode: true);

    test("#1", () {
      final data = "[Tuesday, 22 March 2022, 12:51]";
      final match = regex.firstMatch(data);
      expect(match?.namedGroup("date"), equals("Tuesday, 22 March 2022"));
    });

    test("#2", () {
      final data = "[28 Aug 2013, 9:41]";
      final match = regex.firstMatch(data);
      expect(match?.namedGroup("date"), equals("28 Aug 2013"));
    });

    test("#3", () {
      final data = "[Mar 5, 9:41]";
      final match = regex.firstMatch(data);
      expect(match?.namedGroup("date"), equals("Mar 5"));
    });

    test("#4", () {
      final data = "[25 August, 9:41]";
      final match = regex.firstMatch(data);
      expect(match?.namedGroup("date"), equals("25 August"));
    });

    test("#5", () {
      final data = "[9:41, April 5 2022]";
      final match = regex.firstMatch(data);
      expect(match?.namedGroup("date"), equals("April 5 2022"));
    });

    test("#6", () {
      final data = "[9:41, 2022 August 20]";
      final match = regex.firstMatch(data);
      expect(match?.namedGroup("date"), equals("2022 August 20"));
    });

    test("#7", () {
      final data = "Tue, 21 Jan 2021";
      final match = regex.firstMatch(data);
      expect(match?.namedGroup("date"), equals("Tue, 21 Jan 2021"));
    });

    test("#8", () {
      final data = "[Wednesday, 07 March 2018";
      final match = regex.firstMatch(data);
      expect(match?.namedGroup("date"), equals("Wednesday, 07 March 2018"));
    });

    test("#9", () {
      final data = "[Вторник, 22 Марта 2022 Привет мир";
      final match = regex.firstMatch(data);
      expect(match?.namedGroup("date"), equals("Вторник, 22 Марта 2022"));
    });

    test("#10", () {
      final data = "[Вторник, Март 22 2022 Привет мир";
      final match = regex.firstMatch(data);
      expect(match?.namedGroup("date"), equals("Вторник, Март 22 2022"));
    });

    test("#11", () {
      final data = "[Вторник, 2022 Март 22 Привет мир";
      final match = regex.firstMatch(data);
      expect(match?.namedGroup("date"), equals("Вторник, 2022 Март 22"));
    });

    test("#12", () {
      final data = "[Вторник, Март 22, 09:41]";
      final match = regex.firstMatch(data);
      expect(match?.namedGroup("date"), equals("Вторник, Март 22"));
    });
  });

  group("Time", () {
    final regex = RegExp(WhatsAppPatterns.time, caseSensitive: false);

    test("#1", () {
      final data = "21:46, 11/01/2023]";
      final match = regex.firstMatch(data);
      expect(match?.namedGroup("time"), equals("21:46"));
    });

    test("#2 with seconds", () {
      final data = "11/01/23 21:46:50";
      final match = regex.firstMatch(data);
      expect(match?.namedGroup("time"), equals("21:46:50"));
    });
  });
}

void expectRegex(
  RegExp? regex,
  String raw, {
  required String date,
  required String time,
  String? sender,
  required String content,
}) {
  final match = regex?.firstMatch(raw);
  expect(match, isNotNull);
  expect(match!.namedGroup("date"), equals(date), reason: "Invalid date");
  expect(match.namedGroup("time"), equals(time), reason: "Invalid time");
  expect(match.namedGroup("sender"), equals(sender), reason: "Invalid sender");
  expect(match.namedGroup("content"), equals(content),
      reason: "Invalid content");
}
