import 'dart:io';
import 'dart:convert';
import 'package:whats_json/whats_json.dart';

void main() async {
  // file location
  final path = "./example/_chat.txt";

  // load file
  final stream = File(path)
      .openRead()
      .transform(const Utf8Decoder())
      .transform(const LineSplitter());

  // get messages
  final messages = await whatsAppGetMessages(stream, skipSystem: true);
  print("messages count: ${messages.length}");

  // pring messages
  for (final message in messages) {
    print(message);
  }
}
