import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Lightweight, structured application logger without external dependencies.
///
/// `developer.log` only reaches the debugger, and is a no-op in release
/// builds, so warnings and errors are also printed with [debugPrint]. That
/// makes them visible in `adb logcat` (tag `flutter`) on sideloaded release
/// builds, where they are needed to diagnose device-only failures.
abstract final class AppLogger {
  static void info(String message, {String tag = 'App'}) {
    developer.log(message, name: tag, level: 800);
  }

  static void warning(String message, {String tag = 'App'}) {
    developer.log(message, name: tag, level: 900);
    debugPrint('[$tag] WARNING: $message');
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
    debugPrint('[$tag] ERROR: $message${error == null ? '' : ' | $error'}');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }
}
