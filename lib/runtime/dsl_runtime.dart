// Architecture: runtime layer — maps core DSL output to scene nodes.
//
// This layer chains the core pipeline (dsl.dart -> ShapeCommand ->
// DslInterpreter -> Node) and returns a renderable frame. The stage owns the
// single SceneView/camera so multiple nodes can coexist in one shared scene.

import 'package:dondon_live_coding/core/dsl.dart';
import 'package:dondon_live_coding/core/dsl_result.dart';
import 'package:dondon_live_coding/core/interpreter.dart';
import 'package:dondon_live_coding/core/osc_material.dart';
import 'package:flutter_scene/scene.dart';

class DslFrame {
  const DslFrame({
    required this.commands,
    required this.nodes,
    this.animatedMaterials = const [],
  });

  final List<ShapeCommand> commands;
  final List<Node> nodes;
  final List<OscMaterial> animatedMaterials;
}

class DslRuntime {
  DslRuntime({DslInterpreter? interpreter})
    : _interpreter = interpreter ?? ShapeCommandInterpreter();

  final DslInterpreter _interpreter;

  Future<DslResult<DslFrame>> evaluate(String source) async {
    final script = await runCircleScript(source);
    if (!script.isOk || script.value == null) {
      return script.mapErrors<DslFrame>();
    }

    final parsed = ShapeCommand.parseMany(script.value!);
    if (!parsed.isOk || parsed.value == null) {
      return parsed.mapErrors<DslFrame>();
    }

    final nodes = <Node>[];
    for (final command in parsed.value!) {
      final node = _interpreter.interpret(command);
      if (!node.isOk || node.value == null) {
        return node.mapErrors<DslFrame>();
      }
      nodes.add(node.value!);
    }

    final interpreter = _interpreter;
    final animatedMaterials = interpreter is AnimatedMaterialSource
        ? (interpreter as AnimatedMaterialSource).takeAnimatedMaterials()
        : const <OscMaterial>[];

    return DslResult.ok(
      DslFrame(
        commands: parsed.value!,
        nodes: nodes,
        animatedMaterials: animatedMaterials,
      ),
    );
  }
}
