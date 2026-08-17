// Architecture: runtime layer — maps core DSL output to draw-only components.
//
// This layer chains the core pipeline (dsl.dart -> ShapeCommand ->
// DslInterpreter -> Node), then chooses a component using a ShapeType registry.
// Core remains widget-free; runtime is the adapter to Flutter UI widgets.

import 'package:dondon_live_coding/components/circle_component.dart';
import 'package:dondon_live_coding/components/rect_component.dart';
import 'package:dondon_live_coding/core/dsl.dart';
import 'package:dondon_live_coding/core/dsl_result.dart';
import 'package:dondon_live_coding/core/interpreter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart';

class DslFrame {
  const DslFrame({required this.command, required this.node});

  final ShapeCommand command;
  final Node node;
}

class DslRuntime {
  DslRuntime({
    DslInterpreter? interpreter,
    Map<ShapeType, Widget Function(Scene)>? registry,
  }) : _interpreter = interpreter ?? const ShapeCommandInterpreter(),
       _registry = registry ?? _defaultRegistry;

  final DslInterpreter _interpreter;
  final Map<ShapeType, Widget Function(Scene)> _registry;

  Future<DslResult<DslFrame>> evaluate(String source) async {
    final script = await runCircleScript(source);
    if (!script.isOk || script.value == null) {
      return script.mapErrors<DslFrame>();
    }

    final parsed = ShapeCommand.parse(script.value!);
    if (!parsed.isOk || parsed.value == null) {
      return parsed.mapErrors<DslFrame>();
    }

    final node = _interpreter.interpret(parsed.value!);
    if (!node.isOk || node.value == null) {
      return node.mapErrors<DslFrame>();
    }

    return DslResult.ok(DslFrame(command: parsed.value!, node: node.value!));
  }

  Widget componentFor(DslFrame frame, Scene scene) {
    final builder = _registry[frame.command.type];
    if (builder != null) {
      return builder(scene);
    }

    return CircleComponent(scene: scene);
  }
}

final Map<ShapeType, Widget Function(Scene)> _defaultRegistry = {
  ShapeType.circle: (scene) => CircleComponent(scene: scene),
  ShapeType.rect: (scene) => RectComponent(scene: scene),
};
