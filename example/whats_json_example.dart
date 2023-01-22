import 'dart:io';
import 'dart:convert';
import 'package:whats_json/whats_json.dart';

void main() async {
  // file location
  final path = "_chat.txt";

  // load file
  final stream = File(path)
    .openRead()
    .transform(const Utf8Decoder())
    .transform(const LineSplitter());

  // get messages
  final iterable = await whatsAppGetMessages(stream, skipSystem: true);
  final messages = iterable.toList();
  print("messages count: ${messages.length}");

  // pring messages
  for (var i = 0; i < messages.length; i++) {
    final message = messages[i];
    print(message);
  }
}
