import 'package:dondon_live_coding/core/dsl_result.dart';
import 'package:dondon_live_coding/core/interpreter.dart';
import 'package:dondon_live_coding/runtime/dsl_runtime.dart';
import 'package:flutter_scene/scene.dart';
import 'package:flutter_test/flutter_test.dart';

class _OkInterpreter implements DslInterpreter {
  const _OkInterpreter();

  @override
  DslResult<Node> interpret(ShapeCommand command) {
    return DslResult.ok(Node());
  }
}

class _CircleValidationInterpreter implements DslInterpreter {
  const _CircleValidationInterpreter();

  @override
  DslResult<Node> interpret(ShapeCommand command) {
    if (command.type == ShapeType.circle && command.args.first <= 0) {
      return DslResult.error('circle(radius) requires a positive radius.');
    }

    return DslResult.ok(Node());
  }
}

void main() {
  test('DslRuntime evaluates valid circle script', () async {
    final runtime = DslRuntime(interpreter: const _OkInterpreter());

    const source = '''
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

    final result = await runtime.evaluate(source);

    expect(result.isOk, isTrue);
    expect(result.value, isNotNull);
    expect(result.value!.command.type.name, 'circle');
  });

  test('DslRuntime reports invalid geometry without throwing', () async {
    final runtime = DslRuntime(
      interpreter: const _CircleValidationInterpreter(),
    );

    const source = '''
author "Anushka";
version 1.0.0;
name "Circle Demo";
description "Render a circle from DScript";

contract Canvas {
  impl render() -> string {
    return out(circle(-1.0));
  }
}
''';

    final result = await runtime.evaluate(source);

    expect(result.isOk, isFalse);
    expect(result.firstError, isNotNull);
    expect(result.firstError!.message, contains('positive radius'));
  });
}
