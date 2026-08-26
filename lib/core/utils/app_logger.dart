import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLog {
  AppLog._();

  static void debug(String message) => _log(LogLevel.debug, message);
  static void info(String message) => _log(LogLevel.info, message);
  static void warning(String message) => _log(LogLevel.warning, message);
  static void error(String message, [Object? error, StackTrace? stack]) {
    _log(LogLevel.error, message);
    if (error != null && kDebugMode) {
      debugPrint('   ↳ $error');
      if (stack != null) debugPrint(stack.toString());
    }
  }

  static void _log(LogLevel level, String message) {
    if (!kDebugMode && level != LogLevel.error) return;
    final String tag = switch (level) {
      LogLevel.debug => 'DEBUG',
      LogLevel.info => 'INFO',
      LogLevel.warning => 'WARN',
      LogLevel.error => 'ERROR',
    };
    debugPrint('[$tag][متتبع البصمة] $message');
  }
}
