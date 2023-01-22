import 'dart:collection';
import 'package:mime/mime.dart';
import 'helpers/date_formatter.dart';
import 'helpers/time_formatter.dart';
import 'models/message.dart';

part 'patterns.dart';
part 'media_processor.dart';

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

    message = processMessage(message!, skipSystem, dateFormatter, timeFormatter);
    if (message != null) {
      messages.addFirst(message!);
      message = null;
    }
  }

  /// Try to get [Message] object from string line using regular message format (icnludes media)
  Message? processRegularMessage(String line) {
    Message? data;
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

        data = Message(type: "message", sender: sender, content: content, dateString: date, timeString: time);
        break;
      }

      // pattern not found
      if (systemRegex == null) triesLeft--;
      if (messageRegex == null) return null;
    } else {
      // process using existing pattern
      data = lineToMessage(line, messageRegex!, type: "message");
    }
    if (data == null) return null;

    // check if message contains system text
    if (WhatsAppPatterns.isSystemMessageText(data.content)) { 
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
  dateFormatter.fixDates(messages);

  // save resulting patterns
  /*File logFile = File("_log.txt"); 
  if (!await logFile.exists()) {
    try {
      await logFile.create();
      final patterns = "${messageRegex?.pattern}\n${systemRegex?.pattern}\n${dateFormatter.pattern}\n${timeFormatter.pattern}";
      await logFile.writeAsString(patterns);
    } catch(_) { }
  }*/

  return messages.map((e) => e.toMap());
}

/// Parse line to [Message] object
Message? lineToMessage(String message, RegExp regex, { 
  required String type, bool skipSender = false
}) {
  final match = regex.firstMatch(message);
  if (match == null) return null;

  final String date = match.namedGroup("date") ?? "";
  final String time = match.namedGroup("time") ?? "";
  String? sender;
  if (!skipSender) sender = match.namedGroup("sender");
  final String content = match.namedGroup("content") ?? "";

  return Message(type: type, sender: sender, content: content, dateString: date, timeString: time);
}

/// Process message
Message? processMessage(Message message, bool skipSystem, DateFormatter dateFormatter, TimeFormatter timeFormatter) {
  // skip system messages
  if (message.isSystem && skipSystem) return null;

  // convert date and time strings to int values 
  // time
  final time = timeFormatter.parseString(message.timeString);
  message.time = time;
  if (!dateFormatter.shouldFix) {
    // date
    final date = dateFormatter.parseString(message.dateString);
    message.date = date;
    // combined
    message.dateTime = date + time;
  }

  return message; 
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