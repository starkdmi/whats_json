import 'dart:developer' as developer;

/// Used to log internal operations
abstract class ParserLogger {
  /// high level operations
  void info(String data);

  /// low lever operations
  void debug(String data);

  /// sync errors
  void error(String data, Object error, StackTrace stackTrace);
}

/// Basic logger implementation
class SimpleLogger implements ParserLogger {
  @override
  void info(String data) => developer.log(data, name: "info");

  @override
  void debug(String data) => developer.log(data, name: "debug");

  @override
  void error(String data, Object error, StackTrace stackTrace) {
    developer.log(data, name: "error", error: error, stackTrace: stackTrace);
  }
}
