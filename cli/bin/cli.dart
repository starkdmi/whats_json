import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:whats_json/whats_json.dart';

void main(List<String> arguments) async {
  // setup
  final parser = ArgParser()
  ..addOption("input-file", abbr: 'i', mandatory: true)
  ..addOption("output-file", abbr: 'o', mandatory: true)
  ..addFlag("pretty", negatable: true, abbr: 'p', defaultsTo: false)
  ..addFlag("force", negatable: true, abbr: 'f', defaultsTo: false);

  // parse
  ArgResults argResults = parser.parse(arguments);

  bool pretty = argResults["pretty"];
  bool override = argResults["force"];
  
  final input = argResults["input-file"];
  final inputFile = File(input);
  if (!input.endsWith(".txt") || !inputFile.existsSync()) {
    stdout.writeln("Invalid input file");
    exit(127);
  }

  final output = argResults["output-file"];
  final outputFile = File(output);
  if (!output.endsWith(".json")) {
    stdout.writeln("Invalid output file extension");
    exit(127);
  }
  final exists = outputFile.existsSync();
  if (exists && !override) {
    stdout.writeln("Output file already exists");
    exit(127);
  }

  // read input file
  final stream = inputFile
    .openRead()
    .transform(const Utf8Decoder())
    .transform(const LineSplitter());

  // process file
  final messages = await whatsAppGetMessages(stream);
  stdout.writeln("Messages count: ${messages.length}");

  // output
  String contents;
  if (pretty) {
   contents = JsonEncoder.withIndent("  ").convert(messages);
  } else {
    contents = jsonEncode(messages);
  }
  if (!exists) await outputFile.create();
  await outputFile.writeAsString(contents);
  stdout.writeln("Saved: ${outputFile.path}");

  exit(0);
}