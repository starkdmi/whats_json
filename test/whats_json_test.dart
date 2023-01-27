import 'dart:io';
import 'dart:convert';
import 'package:collection/collection.dart' show ListEquality;
import 'package:test/test.dart';
import 'package:whats_json/src/helpers/date_formatter.dart';
import 'package:whats_json/whats_json.dart';

const listEquality = ListEquality();

void main() async {
  String current = Directory.current.path;
  if (!current.endsWith("test")) current += "/test";
  final path = "$current/data/chats_unique/WhatsApp Chat - Dmitry S.txt";

  final messages = await readMessages(path, skipSystem: false);
  // print(messages);

  group("Simple tests", () {
    test("Messages count", () {
      expect(messages.length, equals(23));
    });

    test("Earliest message date time", () {
      final earliestMessage = messages.last;
      expect(earliestMessage, isNotNull);
      expect(
          earliestMessage["date"],
          equals(DateTime.utc(2022, 3, 18, 14, 56, 01)
              .secondsSinceEpoch)); // 3/18/22, 14:56:01
    });

    test("Newest message date time", () {
      final newestMessage = messages.first;
      expect(newestMessage, isNotNull);
      expect(
          newestMessage["date"],
          equals(DateTime.utc(2022, 3, 27, 21, 56, 46)
              .secondsSinceEpoch)); // 3/27/22, 21:56:46
    });
  });

  group("Text message", () {
    test("Simple text message", () {
      final textMessage = messages[4];
      expect(
          textMessage,
          equals({
            "author": "Dmitry S",
            "date": 1648418010,
            "type": "text",
            "text": "Hello World",
          }));
    });

    test("Emoji message exists and content emoji encoded into the text", () {
      final search = messages.where(
          (message) => message["type"] == "text" && message["text"] == "😊");
      expect(search, isNotEmpty);
    });

    test("Deleted messages should not be presented as text message", () {
      final youDeleted = "You deleted this message.".runes.toList();
      final senderDeleted = "This message was deleted.".runes.toList();

      final search = messages.where((message) {
        if (message["type"] != "text") return false;
        final runes = message["text"].runes.skip(1).toList();
        return listEquality.equals(runes, youDeleted) ||
            listEquality.equals(runes, senderDeleted);
      });
      expect(search, isEmpty);
    });
  });

  test("Replied message", () {
    // Warning: replying message isn't attached by whatsapp
    final search = messages.where((message) =>
        message["type"] == "text" &&
        message["text"] == "This message is reply to another");
    expect(search, isNotEmpty);
  });

  test("Forwarded message", () {
    // Warning: forwarded message is just a copy of original
    final search = messages.where((message) =>
        message["type"] == "text" && message["text"] == "Hello World");
    expect(search.length, 2);
  });

  group("Image attachment", () {
    test("Single image", () {
      final search = messages.where((message) =>
          message["type"] == "image" &&
          message["uri"].endsWith("00000035-PHOTO-2022-03-27-21-41-55.jpg"));
      expect(search, isNotEmpty);
    });

    test("Image with caption", () {
      // Warning: no caption added by whatsapp, so this is same as `single image`
      final search = messages.where((message) =>
          message["type"] == "image" &&
          message["uri"].endsWith("00000055-PHOTO-2022-03-27-21-53-56.jpg"));
      expect(search, isNotEmpty);
    });

    test("View-once image", () {
      // When view-once is on, text `image omitted` used by whatsapp, we should skip this messages
      final ommited = "image omitted".runes.toList();
      final search = messages.where((message) =>
          message["type"] == "text" &&
          listEquality.equals(message["text"].runes.skip(1).toList(), ommited));
      expect(search, isEmpty);
    });
  });

  group("File attachment", () {
    test("Video", () {
      final search = messages.where((message) =>
          message["type"] == "video" &&
          message["uri"].endsWith("00000057-VIDEO-2022-03-27-21-55-12.mp4"));
      expect(search, isNotEmpty);
    });

    test("Audio", () {
      final search = messages.where((message) =>
          message["type"] == "audio" &&
          message["uri"].endsWith("00000038-AUDIO-2022-03-27-21-44-47.opus"));
      expect(search, isNotEmpty);
    });

    test("GIF attachment", () {
      final search = messages.where((message) =>
          message["type"] == "gif" &&
          message["uri"].endsWith("00000051-GIF-2022-03-27-21-51-57.mp4"));
      expect(search, isNotEmpty);
    });

    test("TXT file", () {
      final search = messages.where((message) =>
          message["type"] == "file" &&
          message["uri"].endsWith("00000046-Some file.txt"));
      expect(search, isNotEmpty);
    });

    test("PDF file", () {
      final search = messages.where((message) =>
          message["type"] == "file" &&
          message["uri"].endsWith("00000047-Resume-Dmitry-Starkov.pdf"));
      expect(search, isNotEmpty);
    });

    test("DOCX file", () {
      final search = messages.where((message) =>
          message["type"] == "file" &&
          message["uri"].endsWith("00000048-Template.docx"));
      expect(search, isNotEmpty);
    });
  });

  group("location", () {
    test("google maps", () {
      final search = messages.where((message) =>
          message["type"] == "location" &&
          message["link"] ==
              "https://maps.google.com/?q=51.5021456,-0.127397" &&
          message["longitude"] == "51.5021456" &&
          message["latitude"] == "-0.127397");
      expect(search, isNotEmpty);
    });

    test("foursquare", () {
      final search = messages.where((message) =>
          message["type"] == "location" &&
          message["link"] ==
              "https://foursquare.com/v/4e89af95e5fa82ad4c0aa03b" &&
          message["text"] == "Pimlico Gardens (London, United Kingdom)");
      expect(search, isNotEmpty);
    });
  });

  test("contact", () {
    final search = messages.where((message) =>
        message["type"] == "file" &&
        message["uri"].endsWith("00000042-TR.vcf"));
    expect(search, isNotEmpty);
  });

  group("sticker", () {
    test("static", () {
      final search = messages.where((message) =>
          message["type"] == "sticker" &&
          message["uri"].endsWith("00000043-STICKER-2022-03-27-21-49-16.webp"));
      expect(search, isNotEmpty);
    });

    test("animated", () {
      final search = messages.where((message) =>
          message["type"] == "sticker" &&
          message["uri"].endsWith("00000044-STICKER-2022-03-27-21-49-19.webp"));
      expect(search, isNotEmpty);
    });
  });

  test("Bad (edited) file should not fail", () async {
    final badPath =
        "$current/data/chats_unique/WhatsApp Chat - Bad +90 531 022 21 53.txt";
    final stream = File(badPath)
        .openRead()
        .transform(const Utf8Decoder())
        .transform(const LineSplitter());
    final badMessages = await whatsAppGetMessages(stream, skipSystem: false);
    expect(badMessages.length, 8);
  });

  group("Football group chat", () {
    late List<Map<String, dynamic>> messages;

    setUpAll(() async {
      messages = await readMessages(
          "$current/data/chats_unique/WhatsApp Chat - Group_NoMedia Football Sunday 10am.txt",
          skipSystem: true);
    });

    test("Multiline text message", () {
      final multiLineMessage =
          "koray\nmatt\nrich\nmel \ndave \nvictor\ndimitri?\nAlex?";

      final search = messages.where((message) =>
          message["type"] == "text" &&
          message["date"] ==
              DateTime.utc(2022, 2, 1, 18, 13, 27).secondsSinceEpoch &&
          message["author"] == "\u202A+90 514 771 05 38\u202C" &&
          message["text"] == multiLineMessage);
      expect(search, isNotEmpty);
    });

    test("Messages count", () {
      expect(messages.length, 4); // 4 without system and 12 with
    });

    test("Usupported system messages", () {
      final search = messages.where((message) =>
          message["type"] == "text" &&
          (message["text"].startsWith("You were added") ||
              message["text"] == "+90 535 540 20 75 left"));
      expect(search, isEmpty);
    });
  });

  group("2017 en group chat", () {
    late List<Map<String, dynamic>> messages;

    setUpAll(() async {
      messages = await readMessages(
          "$current/data/chats_unique/WhatsApp Chat - Group_NoMedia 2017.txt",
          skipSystem: true);
    });

    test("Messages count", () {
      expect(messages.length, 3);
    });
  });

  group("2019 ru group chat", () {
    late List<Map<String, dynamic>> messages;

    setUpAll(() async {
      messages = await readMessages(
          "$current/data/chats_unique/WhatsApp Chat - Group_NoMedia 2019 RU.txt",
          skipSystem: true);
    });

    test("Messages count", () {
      expect(messages.length, 12);
    });
  });
}

Future<List<Map<String, dynamic>>> readMessages(String path,
    {required bool skipSystem}) async {
  final stream = File(path)
      .openRead()
      .transform(const Utf8Decoder())
      .transform(const LineSplitter());

  return await whatsAppGetMessages(stream, skipSystem: skipSystem);
}
