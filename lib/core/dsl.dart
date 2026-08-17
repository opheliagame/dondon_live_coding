import 'package:antlr4/antlr4.dart';
import 'package:dondon_live_coding/core/dsl_result.dart';
import 'package:dondon_live_coding/core/logger.dart';
import 'package:dscript_dart/dscript_dart.dart';

final _log = AppLogger.get('app.dsl');
const _hostBindingNames = ['circle', 'rect', 'out'];

// Edit this string to test the DSL. Keep the call style as out(circle(...)).
String get circleScriptSource => '''
author "Anushka";
version 1.0.0;
name "Circle Demo";
description "Render a circle from DScript";

contract Canvas {
  impl render() -> string {
    return out(circle(64.0));
	}
}
''';

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
    .bind<String>('out', (String shape) => shape)
    .param(PrimitiveType.STRING)
    .describe('Emits a shape command to the host renderer.')
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
