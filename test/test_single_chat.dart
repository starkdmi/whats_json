import 'dart:io';
import 'dart:convert';
import 'package:whats_json/whats_json.dart';

void main() async {
  // file location
  // final path = "./test/data/chats_unique/WhatsApp Chat - Elon Musk (EN+Media).txt";
  final path = "./test/data/chats_unique/WhatsApp Chat - Dmitry S.txt";
  // final path = "./test/data/calendars/Japanese iOS.txt";
  // final path = "./test/data/calendars/Buddhist iOS.txt";
  // final path = "./test/data/calendars/Gregorian iOS.txt";

  // load file
  final stream = File(path)
    .openRead()
    .transform(const Utf8Decoder())
    .transform(const LineSplitter());

  // get messages
  final messages = await whatsAppGetMessages(stream, skipSystem: true, logger: SimpleLogger());
  print("messages count: ${messages.length}");

  // pring messages
  for (final message in messages) {
    print(message);
  }
}
