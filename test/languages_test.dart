import 'dart:io';
import 'package:path/path.dart' show basenameWithoutExtension;
import 'package:test/test.dart';
import 'whats_json_test.dart';

void main() async {
  String current = Directory.current.path;
  if (!current.endsWith("test")) current += "/test";
  final path = "$current/data/languages/";
  final directory = Directory(path);

  List<String> ios = [], android = [], iosMedia = [], androidMedia = [];
  await for (final entry in directory.list()) {
    if (!entry.path.endsWith(".txt")) continue;

    bool isIos = entry.path.contains("ios");
    bool isAndroid = entry.path.contains("android");
    bool isMedia = entry.path.contains("media");

    if (isIos) {
      if (isMedia) {
        iosMedia.add(entry.path);
      } else {
        ios.add(entry.path);
      }
    } else if (isAndroid) {
      if (isMedia) {
        androidMedia.add(entry.path);
      } else {
        android.add(entry.path);
      }
    }
  }

  group("Languages", () {
    test("iOS", () async {
      for (final path in ios) {
        final filename =
            basenameWithoutExtension(path).replaceFirst("_ios.txt", "");
        final messages = await readMessages(path, skipSystem: false);

        expect(messages.length, equals(23),
            reason: "$filename: Messages count");

        // four text messages
        final textMessages = messages.where((m) => m["type"] == "text");
        expect(textMessages.length, equals(4), reason: "$filename: Text");

        // two locations
        final locationMessages = messages.where((m) => m["type"] == "location");
        expect(locationMessages.length, equals(2),
            reason: "$filename: Location - count");

        // one foursquare location with caption
        final foursquareLocations =
            locationMessages.where((l) => l["text"] != null);
        expect(foursquareLocations.length, equals(1),
            reason: "$filename: Location - foursquare");

        // one google maps location
        final googleLocations = locationMessages
            .where((l) => l["longitude"] != null && l["latitude"] != null);
        expect(googleLocations.length, equals(1),
            reason: "$filename: Location - google maps");

        final systemMessages = messages.where((m) => m["type"] == "system");
        expect(systemMessages.length, equals(17), reason: "$filename: System");
      }
    });

    test("Android", () async {
      for (final path in android) {
        final filename =
            basenameWithoutExtension(path).replaceFirst("_android.txt", "");
        final messages = await readMessages(path, skipSystem: false);

        expect(messages.length, equals(60),
            reason: "$filename: Messages count");

        // four text messages
        final textMessages = messages.where((m) => m["type"] == "text");
        expect(textMessages.length, equals(15), reason: "$filename: Text");

        // two files (contact cards)
        final fileMessages = messages.where((m) => m["type"] == "file");
        expect(fileMessages.length, equals(2), reason: "$filename: File");

        // three locations
        final locationMessages = messages.where((m) => m["type"] == "location");
        expect(locationMessages.length, equals(3),
            reason: "$filename: Location - count");

        // one foursquare location with caption
        final foursquareLocations =
            locationMessages.where((l) => l["text"] != null);
        expect(foursquareLocations.length, equals(1),
            reason: "$filename: Location - foursquare");

        // two google maps location
        final googleLocations = locationMessages
            .where((l) => l["longitude"] != null && l["latitude"] != null);
        expect(googleLocations.length, equals(2),
            reason: "$filename: Location - google maps");

        final systemMessages = messages.where((m) => m["type"] == "system");
        expect(systemMessages.length, equals(40), reason: "$filename: System");
      }
    });

    test("iOS Media", () async {
      for (final path in iosMedia) {
        final filename =
            basenameWithoutExtension(path).replaceFirst("_ios_media.txt", "");
        final messages = await readMessages(path, skipSystem: false);

        expect(messages.length, equals(25),
            reason: "$filename: Messages count");

        final textMessages = messages.where((m) => m["type"] == "text");
        expect(textMessages.length, equals(4), reason: "$filename: Text");

        final imageMessages = messages.where((m) => m["type"] == "image");
        expect(imageMessages.length, equals(3), reason: "$filename: Image");

        final videoMessages = messages.where((m) => m["type"] == "video");
        expect(videoMessages.length, equals(2), reason: "$filename: Video");

        final audioMessages = messages.where((m) => m["type"] == "audio");
        expect(audioMessages.length, equals(1), reason: "$filename: Audio");

        final gifMessages = messages.where((m) => m["type"] == "gif");
        expect(gifMessages.length, equals(1), reason: "$filename: GIF");

        final stickerMessages = messages.where((m) => m["type"] == "sticker");
        expect(stickerMessages.length, equals(2), reason: "$filename: Sticker");

        final fileMessages = messages.where((m) => m["type"] == "file");
        expect(fileMessages.length, equals(4), reason: "$filename: File");

        // two locations
        final locationMessages = messages.where((m) => m["type"] == "location");
        expect(locationMessages.length, equals(2),
            reason: "$filename: Location - count");

        // one foursquare location with caption
        final foursquareLocations =
            locationMessages.where((l) => l["text"] != null);
        expect(foursquareLocations.length, equals(1),
            reason: "$filename: Location - foursquare");

        // one google maps location
        final googleLocations = locationMessages
            .where((l) => l["longitude"] != null && l["latitude"] != null);
        expect(googleLocations.length, equals(1),
            reason: "$filename: Location - google maps");

        final systemMessages = messages.where((m) => m["type"] == "system");
        expect(systemMessages.length, equals(6), reason: "$filename: System");
      }
    });

    test("Android Media", () async {
      for (final path in androidMedia) {
        // TODO: Deutch export file contains less messages
        if (path.contains("deutch_android_media")) continue;

        final filename = basenameWithoutExtension(path)
            .replaceFirst("_android_media.txt", "");
        final messages = await readMessages(path, skipSystem: false);

        expect(messages.length, equals(60),
            reason: "$filename: Messages count");

        final textMessages = messages.where((m) => m["type"] == "text");
        expect(textMessages.length, equals(15), reason: "$filename: Text");

        final imageMessages = messages.where((m) => m["type"] == "image");
        expect(imageMessages.length, equals(2), reason: "$filename: Image");

        final videoMessages = messages.where((m) => m["type"] == "video");
        expect(videoMessages.length, equals(2), reason: "$filename: Video");

        final audioMessages = messages.where((m) => m["type"] == "audio");
        expect(audioMessages.length, equals(1), reason: "$filename: Audio");

        final stickerMessages = messages.where((m) => m["type"] == "sticker");
        expect(stickerMessages.length, equals(4), reason: "$filename: Sticker");

        final fileMessages = messages.where((m) => m["type"] == "file");
        expect(fileMessages.length, equals(2), reason: "$filename: File");

        // three locations
        final locationMessages = messages.where((m) => m["type"] == "location");
        expect(locationMessages.length, equals(3),
            reason: "$filename: Location - count");

        // one foursquare location with caption
        final foursquareLocations =
            locationMessages.where((l) => l["text"] != null);
        expect(foursquareLocations.length, equals(1),
            reason: "$filename: Location - foursquare");

        // two google maps location
        final googleLocations = locationMessages
            .where((l) => l["longitude"] != null && l["latitude"] != null);
        expect(googleLocations.length, equals(2),
            reason: "$filename: Location - google maps");

        final systemMessages = messages.where((m) => m["type"] == "system");
        expect(systemMessages.length, equals(31), reason: "$filename: System");
      }
    });
  });
}
