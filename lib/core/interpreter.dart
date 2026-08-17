// Architecture: back end of the DSL pipeline
// (script -> DScript runtime -> ShapeCommand IR -> scene Node).
//
// - `ShapeCommand` is the intermediate representation (a minimal AST) the
//   script's string output is parsed into; `ShapeType` makes it a tagged union
//   so dispatch is an exhaustive switch with no fallthrough case.
// - `DslInterpreter` is the Interpreter pattern (GoF) and, architecturally, a
//   port: DSL semantics live here while `ShapeCommandInterpreter` is the
//   adapter that knows about flutter_scene. Swapping renderers means adding an
//   implementation, not editing the parser.
// - Every step returns `DslResult` rather than throwing, so a bad command
//   leaves the previously rendered scene intact.

import 'package:dondon_live_coding/core/dsl_result.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

enum ShapeType {
  circle,
  rect;

  static ShapeType? tryFromName(String name) {
    for (final type in ShapeType.values) {
      if (type.name == name) {
        return type;
      }
    }
    return null;
  }
}

/// A shape command emitted by the DSL, e.g. `circle(32.0)`.
class ShapeCommand {
  const ShapeCommand(this.type, this.args);

  static DslResult<ShapeCommand> parse(String source) {
    final match = _pattern.firstMatch(source.trim());
    if (match == null) {
      return DslResult.error(
        'Invalid shape command. Expected formats like circle(32.0) or rect(64.0,32.0).',
        source: source,
      );
    }

    final type = ShapeType.tryFromName(match.group(1)!);
    if (type == null) {
      return DslResult.error(
        'Unsupported shape "${match.group(1)}".',
        source: source,
      );
    }

    final rawArgs = match.group(2)!.trim();
    final args = <double>[];
    if (rawArgs.isNotEmpty) {
      for (final rawArg in rawArgs.split(',')) {
        final value = double.tryParse(rawArg.trim());
        if (value == null) {
          return DslResult.error(
            'Invalid numeric argument "${rawArg.trim()}".',
            source: source,
          );
        }
        args.add(value);
      }
    }

    return DslResult.ok(ShapeCommand(type, args));
  }

  final ShapeType type;
  final List<double> args;

  static final RegExp _pattern = RegExp(r'^([a-zA-Z_]\w*)\((.*)\)$');

  @override
  String toString() => '${type.name}(${args.join(',')})';
}

/// Turns a parsed DSL shape command into a scene node.
abstract class DslInterpreter {
  DslResult<Node> interpret(ShapeCommand command);
}

class ShapeCommandInterpreter implements DslInterpreter {
  const ShapeCommandInterpreter({this.pixelsPerWorldUnit = 40.0});

  final double pixelsPerWorldUnit;

  @override
  DslResult<Node> interpret(ShapeCommand command) {
    switch (command.type) {
      case ShapeType.circle:
        return _circle(command);
      case ShapeType.rect:
        return _rect(command);
    }
  }

  DslResult<Node> _circle(ShapeCommand command) {
    final args = command.args;
    if (args.length != 1) {
      return DslResult.error(
        'circle(...) expects exactly one radius argument.',
        source: '$command',
      );
    }

    final radius = args.first;
    if (radius <= 0) {
      return DslResult.error(
        'circle(radius) requires a positive radius.',
        source: '$command',
      );
    }

    return DslResult.ok(
      Node(
        mesh: Mesh(
          DiscGeometry(radius: radius / pixelsPerWorldUnit, segments: 96),
          UnlitMaterial()..baseColorFactor = vm.Vector4(0.2, 0.55, 1.0, 1.0),
        ),
        localTransform: vm.Matrix4.identity(),
      ),
    );
  }

  DslResult<Node> _rect(ShapeCommand command) {
    final args = command.args;
    if (args.length != 2) {
      return DslResult.error(
        'rect(...) expects exactly two arguments: width, height.',
        source: '$command',
      );
    }

    final width = args[0];
    final height = args[1];
    if (width <= 0 || height <= 0) {
      return DslResult.error(
        'rect(width,height) requires positive width and height.',
        source: '$command',
      );
    }

    return DslResult.ok(
      Node(
        mesh: Mesh(
          PlaneGeometry(
            width: width / pixelsPerWorldUnit,
            depth: height / pixelsPerWorldUnit,
          ),
          UnlitMaterial()..baseColorFactor = vm.Vector4(0.2, 0.9, 0.5, 1.0),
        ),
        localTransform: vm.Matrix4.identity(),
      ),
    );
  }
}
