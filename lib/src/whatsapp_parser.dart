import 'dart:collection';
import 'package:mime/mime.dart';
import 'date_formatter.dart';
import 'time_formatter.dart';
import 'message.dart';

part 'patterns.dart';

/// Helper class to work with mime types of filenames
final mimeTypeResolver = MimeTypeResolver()..addExtension("opus", "audio/opus");

/// Process _chat.txt header lines to Dart objects 
/// if [skipSystem] is `true` system messages will be skipped
/// 
/// File usage
/// final stream = file
///   .openRead()
///   .transform(Utf8Decoder())
///   .transform(LineSplitter());
/// 
/// List usage
/// List<String> list = ...;
/// final stream = Stream.fromIterable(list)
/// 
Future<Iterable<Map<String, dynamic>>> whatsAppGetMessages(Stream<String> stream, { 
  bool skipSystem = false 
}) async {
  // indicates if text should be proceed from right-to-left
  // bool? _isRTL;
  // end if none system and normal messages found in 10 tries
  int triesLeft = 10;
  // active patterns used to parse regular and system messages
  RegExp? messageRegex, systemRegex; 
  // class for date strings processing
  final dateFormatter = DateFormatter();
  // class for time strings processing
  final timeFormatter = TimeFormatter();
  // previous message which wasn't proceed yet 
  Message? message;
  // messages queue - original order 
  var messages = Queue<Message>();

  /// Process previous message
  void processLatestIfExists() async {
    if (message == null) return;

    // skip system messages
    if (message!.isSystem && skipSystem) return;

    // convert date and time strings to int values 
    // time
    final time = timeFormatter.parseString(message!.timeString);
    message!.time = time;
    if (!dateFormatter.shouldFix) {
      // date
      final date = dateFormatter.parseString(message!.dateString);
      message!.date = date;
      // combined
      message!.dateTime = date + time;
    }

    // save message
    messages.addFirst(message!);
    message = null;
  }

  /// Parse line to [Message] object
  Message? lineToMessage(String message, RegExp regex, { required String type, bool skipSender = false}) {
    final match = regex.firstMatch(message);
    if (match == null) return null;

    final String date = match.namedGroup("date") ?? "";
    final String time = match.namedGroup("time") ?? "";
    String? sender;
    if (!skipSender) sender = match.namedGroup("sender");
    final String content = match.namedGroup("content") ?? "";

    return Message(type: type, sender: sender, content: content, dateString: date, timeString: time);
  }

  /// Detect if message is media type, return updated [Message] object
  Message? parseMedia(Message data) {
    final content = data.content;

    // process body to determine message type
    final attachmentMatch = WhatsAppPatterns._attachmentRegex.firstMatch(content);
    final attachment = attachmentMatch?.namedGroup("file") ?? attachmentMatch?.namedGroup("file2");
    final caption = attachmentMatch?.namedGroup("caption");
    if (attachment == null) {

      // check if location is present in body's text 
      String? location, place, longitude, latitude;
      
      // google link with coordinates
      final googleMatch = WhatsAppPatterns._googleLocationRegex.firstMatch(content);
      if (googleMatch != null) {
        location = googleMatch.namedGroup("link"); 
        longitude = googleMatch.namedGroup("longitude");
        latitude = googleMatch.namedGroup("latitude");
      }
      
      // foursquare link with optional text
      final line = content.replaceAll("\n", " "); // fix Android multiline location message
      final foursquareMatch = WhatsAppPatterns._foursquareLocationRegex.firstMatch(line);
      if (foursquareMatch != null) {
        location ??= foursquareMatch.namedGroup("link"); 
        place = foursquareMatch.namedGroup("place")?.trim();
        // remove trailing semicolon
        if (place != null && place.endsWith(":")) {
          place = place.substring(0, place.length - 1);
        } 
      }

      if (location != null) {
        // Location
        data.type = "location";
        data.fields = {
          "link": location,
          if (place != null) "text": place,
          if (longitude != null) "longitude": longitude,
          if (latitude != null) "latitude": latitude,
        };
      } else {
        // Text
        data.type = "text";
        data.fields = {
          "text": content,
        };
      }
    } else {
      // ignore: unnecessary_string_interpolations
      String filename = "$attachment"; 
      if (filename.length > 9 && int.tryParse(filename.substring(0, 8)) != null && filename[8] == "-") {
        // skip attachment id + `-` symbol
        filename = filename.substring(9);
      }

      String type;
      // try to get file type using WhatsApp file name
      if (filename.startsWith("PHOTO-") || filename.startsWith("IMG-")) {
        type = "image";
      } else if (filename.startsWith("GIF-")) {
        // GIF exported as mp4
        type = "gif";
      } else if (filename.startsWith("VIDEO-") || filename.startsWith("VID-")) {
        type = "video";
      } else if (filename.startsWith("AUDIO-") || filename.startsWith("PTT-")) {
        type = "audio";
      } else if (filename.startsWith("STICKER-") || filename.startsWith("STK-")) {
        type = "sticker";
      } else {
        // detect file type using mime package
        final mimeType = mimeTypeResolver.lookup(attachment);
        // headerBytes allow to detect type based on file header 

        // get file type using mime package
        if (mimeType?.startsWith("image") == true) {
          type = "image";
        } else if (mimeType?.startsWith("video") == true) {
          type = "video";
        } else if (mimeType?.startsWith("audio") == true) {
          type = "audio";
        } else {
          type = "file";
        }
      }

      data.type = type;
      data.fields = {
        // "name": filename,
        "uri": attachment,
        // "mime": mimeType
        if (caption != null && caption.trim().isNotEmpty) "text": caption
      };
    }

    return data;
  }

  /// Try to get [Message] object from string line using regular message format (icnludes media)
  Message? processRegularMessage(String line) {
    if (messageRegex == null) {
      // detect message format
      for (final pattern in WhatsAppPatterns.messageFormats) {
        final regex = RegExp(pattern, caseSensitive: false);

        final match = regex.firstMatch(line);
        if (match == null) continue;
        final date = match.namedGroup("date");
        if (date == null) continue;
        final time = match.namedGroup("time");
        if (time == null) continue;
        final sender = match.namedGroup("sender");
        if (sender == null) continue;
        final content = match.namedGroup("content");
        if (content == null) continue;

        messageRegex = regex; // save pattern

        return Message(type: "message", sender: sender, content: content, dateString: date, timeString: time);
      }

      // pattern not found
      if (systemRegex == null) triesLeft--;
      return null;
    }

    final data = lineToMessage(line, messageRegex!, type: "message");
    if (data == null) return null;

    // check if message contains system text
    if (isSystemMessageText(data.content)) { 
      data.type = "system";
      return data;
    }

    // parse attachments and locations
    return parseMedia(data);
  }

  /// Try to get [Message] object from string line using system message format
  Message? processSystemMessage(String line) {
    if (systemRegex == null) {
      // try multiple system message formats
      for (final pattern in WhatsAppPatterns.systemMessageFormats) {
        final regex = RegExp(pattern, caseSensitive: false);
        final match = regex.firstMatch(line);
        if (match == null) continue;   
        final dateString = match.namedGroup("date"); 
        if (dateString == null) continue;
        final timeString = match.namedGroup("time"); 
        if (timeString == null) continue;
        final content = match.namedGroup("content"); 
        if (content == null) continue;

        return Message(type: "system", content: content, dateString: dateString, timeString: timeString);
      }

      // pattern not found
      if (systemRegex == null) return null;
    }

    return lineToMessage(line, systemRegex, type: "system");
  }

  /// Process current string line using regular and system patterns
  void processLine(String line) async {
    line = escapeMessage(line); // isRTL

    // try to process regular messages
    var data = processRegularMessage(line);
    if (data != null) {
      processLatestIfExists();
      message = data;
      return;
    }

    // try to process system messages
    data = processSystemMessage(line);
    if (data != null) {
      processLatestIfExists();
      message = data;
      return;
    }

    // append plain text to previous message if exists, skip otherwise
    if (message != null) {
      message!.content += "\n$line";
    }
  }

  /// Main loop over stream lines
  await for (var line in stream) {
    // Check RTL of first message
    // isRTL ??= Bidi.estimateDirectionOfText(line) == TextDirection.RTL;

    // finish if message format not found in time
    if (messageRegex == null && systemRegex == null && triesLeft < 0) break;

    processLine(line);
  }
  processLatestIfExists();

  // fix dates
  bool fixed;
  if (messages.isNotEmpty && dateFormatter.shouldFix) {
    fixed = dateFormatter.fix(messages);
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

  // save resulting patterns
  /*File logFile = File("$path/_log.txt"); 
  if (!await logFile.exists()) {
    try {
      await logFile.create();
      final patterns = "${MessageRegex?.pattern}\n${_systemRegex?.pattern}\n${_dateFormatter._dateFormat?.pattern}\n${_timeFormatter._timeFormat?.pattern}";
      await logFile.writeAsString(patterns);
    } catch(_) { }
  }*/

  return messages.map((e) => e.toMap());
}

/// Check if message text contains system message like `image omitted` or `This message was deleted`
bool isSystemMessageText(String message) {
  return WhatsAppPatterns.isEncryptedSystemMessage(message) ||  
    WhatsAppPatterns.isDeletedMessage(message) || 
    WhatsAppPatterns.isDeletedByYouMessage(message) || 
    WhatsAppPatterns.isSecurityCodeChangedMessage(message) || 
    WhatsAppPatterns.isMissedCallMessage(message) || 
    WhatsAppPatterns.isMissedVideoCallMessage(message) || 
    WhatsAppPatterns.isImageOmittedMessage(message) || 
    WhatsAppPatterns.isVideoOmittedMessage(message) || 
    WhatsAppPatterns.isAudioOmittedMessage(message) || 
    WhatsAppPatterns.isStickerOmittedMessage(message) || 
    WhatsAppPatterns.isGIFOmittedMessage(message) || 
    WhatsAppPatterns.isDocumentOmittedMessage(message) || 
    WhatsAppPatterns.isMediaOmittedMessage(message) ||
    WhatsAppPatterns.isContactCardOmittedMessage(message) ||
    WhatsAppPatterns.isDocumentLiveLocationMessage(message) ||
    WhatsAppPatterns.isNullMessage(message);
}

/// Escape hidden unicode characters for Regex processing
String escapeMessage(String message, [bool rtl = false]) {
  if (!rtl) {
    // Left-to-Right Mark (LRM)
   message = message.replaceAll(RegExp(r"(\u{200e})", unicode: true), ""); 
  }

  return message
    .replaceAll(RegExp(r"\u{00a0}", unicode: true), " ") // No-Break Space (NBSP)
    .replaceAll(RegExp(r"\u{feff}", unicode: true), ""); // Zero Width No-Break Space
}

/// Escape bidirectional text unicode characters
/*String escapeMessage(String message) {  
  // message = message.replaceAll(RegExp(r'\u{00a0}', unicode: true), ' '); // No-Break Space (NBSP)

  final rlm = Bidi.RLM.runes.first;
  final rle = Bidi.RLE.runes.first;
  final lrm = Bidi.LRM.runes.first;
  final lre = Bidi.LRE.runes.first;
  final pdf = Bidi.PDF.runes.first;
  final lro = "\u202D".runes.first; 
  final rlo = "\u202E".runes.first;

  // Remove LRM, RLM, LRE, RLE, PDF, LRO, RLO
  final clearRunes = message.runes.where((rune) =>
    rune != rlm && 
    rune != rle && 
    rune != lrm && 
    rune != lre && 
    rune != pdf && 
    rune != lro && 
    rune != rlo
  );
  return String.fromCharCodes(clearRunes);
}*/