import 'dart:developer' as developer;

import 'package:logging/logging.dart';

/// Shared logger setup used by app runtime and build hooks.
class AppLogger {
  static bool _configured = false;

  static void configure({Level level = Level.INFO, bool emitToStdout = false}) {
    if (_configured) {
      return;
    }

    Logger.root.level = level;
    Logger.root.onRecord.listen((record) {
      if (emitToStdout) {
        // ignore: avoid_print
        print(
          '[${record.level.name}] '
          '${record.time.toIso8601String()} '
          '${record.loggerName}: '
          '${record.message}',
        );
      }

      developer.log(
        record.message,
        name: record.loggerName,
        level: record.level.value,
        time: record.time,
        error: record.error,
        stackTrace: record.stackTrace,
      );
    });

    _configured = true;
  }

  static Logger get(String name) => Logger(name);
}
