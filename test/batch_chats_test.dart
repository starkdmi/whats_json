import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:whats_json/whats_json.dart';
import 'package:compute/compute.dart';

void main() {
  group("Test all unique chats (batched)", () {
    final path = "./test/data/chats_unique";
    final directory = Directory(path);

    // tearDown(() => exit(0)); // finish isolates if any (bug in compute method)

    test("Parse all unique chats without failures, timeouts, non-empty and with valid dates", () async {
      int errors = 0;
      int timeouts = 0;
      int lessThanTwoMessages = 0;
      int invalidDates = 0;

      await for (final entry in directory.list()) {
        if (!entry.path.endsWith(".txt")) continue;
        
        // skip unsupported files (Arabic RTL)
        if ([
          "$path/WhatsApp Chat - Elon Musk (Arabic)", 
          "$path/WhatsApp Chat - Arabic_NoMedia Dmitry S"
        ].contains(entry.path)) continue;

        final file = File(entry.path);

        try {
          // print("${entry.path}\n");

          final stream = file
            .openRead()
            .transform(const Utf8Decoder())
            .transform(const LineSplitter());

            await runZonedGuarded(() async {
              TimeoutExecuter api = TimeoutExecuter();
              await api.parseWithTimeout(stream: stream, timeout: Duration(seconds: 20)).then((messages) {
                if (messages == null) {
                  print("Timeout: ${entry.path}\n");
                  // throw "Timeout: ${entry.path}\n";
                  timeouts++;
                } else {              
                  if (messages.length < 2) {
                    print("${messages.length}: ${entry.path}\n");
                    lessThanTwoMessages++;
                  }

                  if (messages.any((m) => m["date"] == null || m["date"] == 0)) {
                    print("Empty dates: ${entry.path}\n");
                    // throw "Empty dates: ${entry.path}\n";
                    invalidDates++;
                  }
                }
              });
            }, (error, _) {
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
    });
  });
}

class TimeoutExecuter {
  late Completer<List<Map<String, dynamic>>?> _completer;
  Timer? _timer;

  Future<List<Map<String, dynamic>>?> parseWithTimeout({ required Stream<String> stream, Duration timeout = const Duration(seconds: 10) }) async {
    _completer = Completer<List<Map<String, dynamic>>?>();

    compute(whatsAppGetMessages, stream).then((response) {
      if (_completer.isCompleted == false) {
        _timer?.cancel();
        _completer.complete(response.toList());
      }
    });

    _timer = Timer(timeout, () {
      if (_completer.isCompleted == false) {
        _completer.complete(null);
      }
    });

    return _completer.future;
  }

  void cancelOperation() {
    _timer?.cancel();
    if (_completer.isCompleted == false) {
      _completer.complete(null);
    }
  }
}