import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:whats_json/whats_json.dart';
import 'dart:isolate';

void main() async {
  group("Test all unique chats (batched)", () {
    final path = "./test/data/chats_unique";
    final directory = Directory(path);

    test("Parse all unique chats without failures, timeouts, non-empty and with valid dates", () async {
      int errors = 0;
      int timeouts = 0;
      int lessThanTwoMessages = 0;
      int invalidDates = 0;

      await for (final entry in directory.list()) {
        if (!entry.path.endsWith(".txt")) continue;

        try {
          // print("${entry.path}\n");

          // TODO: perfomance may be improved by re-using a single or multiple isolates and not spawning new each time
          Isolate? isolate;
          await runZonedGuarded(() async {
            final port = ReceivePort();
            isolate =
                await Isolate.spawn(parseIsolated, [port.sendPort, entry.path]);
            Iterable<Map<String, dynamic>>? messages = await port.first
                    .timeout(Duration(seconds: 10), onTimeout: () => null)
                as Iterable<Map<String, dynamic>>?;
            if (messages == null) {
              print("Timeout ${entry.path}\n");
              timeouts++;
              return;
            }
            if (messages.length < 2) {
              print("${messages.length}: ${entry.path}\n");
              lessThanTwoMessages++;
            }

            if (messages.any((m) => m["date"] == null || m["date"] == 0)) {
              print("Empty dates: ${entry.path}\n");
              // throw "Empty dates: ${entry.path}\n";
              invalidDates++;
            }
          }, (error, _) {
            isolate?.kill();
            print("$error ${entry.path}\n");
            errors++;
          });
        } catch (error) {
          print("$error ${entry.path}\n");
          errors++;
        }
      }

      expect(errors, equals(0));
      expect(timeouts, equals(0));
      expect(lessThanTwoMessages, equals(0));
      expect(invalidDates, equals(0));
    }, timeout: Timeout(Duration(minutes: 15)));
  });
}

Future<void> parseIsolated(List<dynamic> args) async {
  SendPort port = args.first as SendPort;
  String path = args.last as String;

  final stream = File(path)
      .openRead()
      .transform(const Utf8Decoder())
      .transform(const LineSplitter());

  final messages = await whatsGetMessages(stream, skipSystem: false);
  Isolate.exit(port, messages);
}
