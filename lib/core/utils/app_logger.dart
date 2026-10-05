import 'dart:developer' as developer;

/// Lightweight, structured application logger without external dependencies.
abstract final class AppLogger {
  static void info(String message, {String tag = 'App'}) {
    developer.log(message, name: tag, level: 800);
  }

  static void warning(String message, {String tag = 'App'}) {
    developer.log(message, name: tag, level: 900);
  }

  static void error(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
