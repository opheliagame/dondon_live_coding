// Architecture: error-handling layer of the DSL pipeline.
//
// Pattern: Result/Either type carrying a Notification (a queue of errors)
// instead of throwing. Callers thread results through the pipeline and
// short-circuit on the first failure (railway-oriented programming), which
// suits a live-coding environment where invalid input is expected, not
// exceptional, and must never crash or blank the running visual.
//
// The error store is a FIFO queue so the UI can peek the oldest error
// (`firstError`) and `popError()` once it has been acknowledged.

import 'dart:collection';

/// An error produced while parsing or interpreting a DSL command.
class DslError {
  const DslError(this.message, {this.source});

  final String message;
  final String? source;

  @override
  String toString() => source == null ? message : '$message (in "$source")';
}

/// Result of a DSL step: either a value, or a FIFO queue of errors so the UI
/// can show the oldest one first and pop it once acknowledged.
class DslResult<T> {
  DslResult.ok(T value) : _value = value, _errors = Queue<DslError>();

  DslResult.fail(Iterable<DslError> errors)
    : _value = null,
      _errors = Queue<DslError>.of(errors);

  factory DslResult.error(String message, {String? source}) =>
      DslResult.fail([DslError(message, source: source)]);

  final T? _value;
  final Queue<DslError> _errors;

  bool get isOk => _errors.isEmpty;
  bool get hasErrors => _errors.isNotEmpty;

  T? get value => _value;

  /// Oldest unacknowledged error, or null when there is none.
  DslError? get firstError => _errors.isEmpty ? null : _errors.first;

  /// Removes and returns the oldest error.
  DslError? popError() => _errors.isEmpty ? null : _errors.removeFirst();

  DslResult<R> mapErrors<R>() => DslResult<R>.fail(_errors);
}
