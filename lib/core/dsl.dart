// Architecture: front end of the DSL pipeline.
//
// The user's script is sandboxed in the DScript VM rather than evaluated as
// Dart, so a bad script during a performance cannot take down the app. The
// host exposes primitives (`circle`, `rect`, `rotate`, `out`) as a contract of external
// bindings; those bindings return command strings, keeping the boundary
// between the sandbox and the renderer a plain serialisable value.
//
// Analysis, compilation and execution failures are returned as `DslResult`
// errors so the caller can keep the last good frame on screen.

import 'package:antlr4/antlr4.dart';
import 'package:dondon_live_coding/core/dsl_result.dart';
import 'package:dondon_live_coding/core/logger.dart';
import 'package:dscript_dart/dscript_dart.dart';

final _log = AppLogger.get('app.dsl');
const _hostBindingNames = ['circle', 'rect', 'osc', 'rotate', 'out'];

// Edit this string to test the DSL.
String get circleScriptSource => '''
author "opheliagame";
version 1.0.0;
name "dondon demo";
description "demo a live coding flutter environment";

contract Canvas {
  impl render() -> string {
    return out(
      osc(20.0, 0.1, 0.8),
      out(
        rotate(
          12, 
          rect(14.0,12.0)
        ),
        circle(12.0)
      )
    );
  }
}
''';

const _commandSeparator = ';';

String _normalizeExternalBindingCalls(String source) {
  var normalized = source;

  for (final name in _hostBindingNames) {
    final pattern = RegExp('(?<!external::)\\b$name\\s*\\(');
    normalized = normalized.replaceAllMapped(pattern, (_) {
      return 'external::$name(';
    });
  }

  return normalized;
}

final ContractSignature _canvasContract = contract('Canvas')
    .impl('render', returnType: PrimitiveType.STRING)
    .describe('Computes a shape command and outputs it for the host app.')
    .end()
    .bind<String>('circle', (double radius) => 'circle($radius)')
    .param(PrimitiveType.DOUBLE)
    .describe('Constructs a circle shape command.')
    .end()
    .bind<String>(
      'rect',
      (double width, double height) => 'rect($width,$height)',
    )
    .param(PrimitiveType.DOUBLE)
    .param(PrimitiveType.DOUBLE)
    .describe('Constructs a rectangle shape command.')
    .end()
    .bind<String>('osc', (double frequency, double sync, double offset) {
      return 'osc($frequency,$sync,$offset)';
    })
    .param(PrimitiveType.DOUBLE)
    .param(PrimitiveType.DOUBLE)
    .param(PrimitiveType.DOUBLE)
    .describe(
      'Constructs an oscillator command: a sine gradient along the x axis, '
      'scrolling at sync and phase-shifted per color channel by offset.',
    )
    .end()
    .bind<String>('rotate', (double degrees, String shape) {
      return 'rotate($degrees,$shape)';
    })
    .param(PrimitiveType.DOUBLE)
    .param(PrimitiveType.STRING)
    .describe('Wraps a shape command with a rotation in degrees.')
    .end()
    .bind<String>('out', (String shape, String restShapes) {
      return '$shape$_commandSeparator$restShapes';
    })
    .param(PrimitiveType.STRING)
    .param(PrimitiveType.STRING)
    .describe(
      'Emits one or more shape commands by recursive composition, e.g. out(a, out(b, c)).',
    )
    .end()
    .build();

Future<DslResult<String>> runCircleScript(String scriptSource) async {
  final normalizedScriptSource = _normalizeExternalBindingCalls(scriptSource);

  final analyzed = analyze(InputStream.fromString(normalizedScriptSource), [
    _canvasContract,
  ]);

  if (analyzed.isError()) {
    final report = analyzed.fold((_) => null, (failure) => failure);
    return DslResult.error('DScript analysis failed: $report');
  }

  final Object? value;
  try {
    final compiled = compile(analyzed.getOrThrow());
    final runtime = Runtime(compiled);
    runtime.grantAll();
    value = await runtime.run('render');
  } catch (e) {
    return DslResult.error('DScript execution failed: $e');
  }

  if (value is! String) {
    return DslResult.error(
      'DScript render() must return a string shape command.',
    );
  }

  if (value.trim().isEmpty) {
    return DslResult.error('DScript shape command must not be empty.');
  }

  _log.info('Rendered shape command from DSL: $value');
  return DslResult.ok(value.trim());
}
