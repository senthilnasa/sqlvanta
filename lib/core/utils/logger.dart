import 'dart:developer' as dev;

/// Structured logger wrapping dart:developer.
/// In release builds, debug/info logs are no-ops.
/// Use [AppLogger.error] for errors that should always surface.
class AppLogger {
  AppLogger._();

  static void debug(String message, {String? tag, Object? error}) {
    assert(() {
      dev.log(message, name: tag ?? 'SQLvanta', error: error, level: 500);
      return true;
    }());
  }

  static void info(String message, {String? tag}) {
    assert(() {
      dev.log(message, name: tag ?? 'SQLvanta', level: 800);
      return true;
    }());
  }

  static void warning(String message, {String? tag, Object? error}) {
    dev.log(
      '[WARN] $message',
      name: tag ?? 'SQLvanta',
      error: error,
      level: 900,
    );
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    dev.log(
      '[ERROR] $message',
      name: tag ?? 'SQLvanta',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
