import 'package:antlr4/antlr4.dart';
import 'package:dondon_live_coding/core/logger.dart';
import 'package:dscript_dart/dscript_dart.dart';

final _log = AppLogger.get('app.dsl');

// Edit this string to test the DSL. Keep the call style as out(circle(...)).
String get circleScriptSource => '''
author "Anushka";
version 1.0.0;
name "Circle Demo";
description "Render a circle from DScript";

contract Canvas {
	impl render() -> double {
		return external::out(external::circle(32.0));
	}
}
''';

final ContractSignature _canvasContract = contract('Canvas')
    .impl('render', returnType: PrimitiveType.DOUBLE)
    .describe('Computes a radius and outputs it for the host app.')
    .end()
    .bind<double>('circle', (double radius) => radius)
    .param(PrimitiveType.DOUBLE)
    .describe('Constructs a circle value from radius.')
    .end()
    .bind<double>('out', (double radius) => radius)
    .param(PrimitiveType.DOUBLE)
    .describe('Emits a radius to the host renderer.')
    .end()
    .build();

Future<double> runCircleScript(String scriptSource) async {
  final analyzed = analyze(InputStream.fromString(scriptSource), [
    _canvasContract,
  ]);

  if (analyzed.isError()) {
    final report = analyzed.fold((_) => null, (failure) => failure);
    throw StateError('DScript analysis failed: $report');
  }

  final compiled = compile(analyzed.getOrThrow());
  final runtime = Runtime(compiled);
  runtime.grantAll();

  final value = await runtime.run('render');
  if (value is! double) {
    throw StateError('DScript render() must return a double radius.');
  }

  if (value.isNaN || value.isInfinite || value <= 0) {
    throw StateError('DScript radius must be a positive finite double.');
  }

  _log.info('Rendered circle radius from DSL: $value');
  return value;
}
