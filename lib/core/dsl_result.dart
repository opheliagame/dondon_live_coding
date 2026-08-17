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
