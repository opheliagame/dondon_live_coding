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
import 'package:dondon_live_coding/core/osc_material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

enum ShapeType {
  circle,
  rect,
  osc,
  rotate;

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
  const ShapeCommand({
    required this.type,
    this.numericArgs = const [],
    this.commandArgs = const [],
  });

  static DslResult<List<ShapeCommand>> parseMany(String source) {
    final commands = <ShapeCommand>[];
    final parts = source
        .split(';')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);

    for (final part in parts) {
      final parsed = parse(part);
      if (!parsed.isOk || parsed.value == null) {
        return parsed.mapErrors<List<ShapeCommand>>();
      }
      commands.add(parsed.value!);
    }

    if (commands.isEmpty) {
      return DslResult.error(
        'Expected at least one shape command.',
        source: source,
      );
    }

    return DslResult.ok(commands);
  }

  static DslResult<ShapeCommand> parse(String source) {
    final match = _pattern.firstMatch(source.trim());
    if (match == null) {
      return DslResult.error(
        'Invalid shape command. Expected circle(...), rect(...), osc(...), or rotate(...).',
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

    final argTokens = _splitTopLevelArgs(match.group(2)!);
    switch (type) {
      case ShapeType.circle:
        if (argTokens.length != 1) {
          return DslResult.error(
            'circle(...) expects exactly one numeric argument.',
            source: source,
          );
        }
        final radius = _parseNumericArg(argTokens.first, source);
        if (!radius.isOk || radius.value == null) {
          return radius.mapErrors<ShapeCommand>();
        }
        return DslResult.ok(
          ShapeCommand(type: type, numericArgs: [radius.value!]),
        );
      case ShapeType.rect:
        if (argTokens.length != 2) {
          return DslResult.error(
            'rect(...) expects exactly two numeric arguments.',
            source: source,
          );
        }
        final width = _parseNumericArg(argTokens[0], source);
        if (!width.isOk || width.value == null) {
          return width.mapErrors<ShapeCommand>();
        }
        final height = _parseNumericArg(argTokens[1], source);
        if (!height.isOk || height.value == null) {
          return height.mapErrors<ShapeCommand>();
        }
        return DslResult.ok(
          ShapeCommand(type: type, numericArgs: [width.value!, height.value!]),
        );
      case ShapeType.osc:
        if (argTokens.length != 3) {
          return DslResult.error(
            'osc(...) expects exactly three arguments: frequency, sync, offset.',
            source: source,
          );
        }

        final numericArgs = <double>[];
        for (final token in argTokens) {
          final parsed = _parseNumericArg(token, source);
          if (!parsed.isOk || parsed.value == null) {
            return parsed.mapErrors<ShapeCommand>();
          }
          numericArgs.add(parsed.value!);
        }

        return DslResult.ok(ShapeCommand(type: type, numericArgs: numericArgs));
      case ShapeType.rotate:
        if (argTokens.length != 2) {
          return DslResult.error(
            'rotate(...) expects exactly two arguments: angle and shape.',
            source: source,
          );
        }

        final degrees = _parseNumericArg(argTokens[0], source);
        if (!degrees.isOk || degrees.value == null) {
          return degrees.mapErrors<ShapeCommand>();
        }

        final inner = parse(argTokens[1]);
        if (!inner.isOk || inner.value == null) {
          return inner.mapErrors<ShapeCommand>();
        }

        return DslResult.ok(
          ShapeCommand(
            type: type,
            numericArgs: [degrees.value!],
            commandArgs: [inner.value!],
          ),
        );
    }
  }

  final ShapeType type;
  final List<double> numericArgs;
  final List<ShapeCommand> commandArgs;

  static final RegExp _pattern = RegExp(r'^([a-zA-Z_]\w*)\((.*)\)$');

  static List<String> _splitTopLevelArgs(String rawArgs) {
    final args = <String>[];
    var depth = 0;
    var start = 0;
    final input = rawArgs.trim();

    if (input.isEmpty) {
      return args;
    }

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '(') {
        depth++;
      } else if (char == ')') {
        depth--;
      } else if (char == ',' && depth == 0) {
        args.add(input.substring(start, i).trim());
        start = i + 1;
      }
    }

    args.add(input.substring(start).trim());
    return args.where((arg) => arg.isNotEmpty).toList();
  }

  static DslResult<double> _parseNumericArg(String rawArg, String source) {
    final value = double.tryParse(rawArg.trim());
    if (value == null) {
      return DslResult.error(
        'Invalid numeric argument "${rawArg.trim()}".',
        source: source,
      );
    }

    return DslResult.ok(value);
  }

  @override
  String toString() {
    switch (type) {
      case ShapeType.circle:
      case ShapeType.rect:
      case ShapeType.osc:
        return '${type.name}(${numericArgs.join(',')})';
      case ShapeType.rotate:
        final angle = numericArgs.isEmpty ? '' : numericArgs.first;
        final inner = commandArgs.isEmpty ? '' : commandArgs.first;
        return '${type.name}($angle,$inner)';
    }
  }
}

/// Turns a parsed DSL shape command into a scene node.
abstract class DslInterpreter {
  DslResult<Node> interpret(ShapeCommand command);
}

/// Implemented by interpreters that produce materials needing a per-frame time
/// update; the stage drives them from its render loop.
abstract interface class AnimatedMaterialSource {
  List<OscMaterial> takeAnimatedMaterials();
}

class ShapeCommandInterpreter
    implements DslInterpreter, AnimatedMaterialSource {
  ShapeCommandInterpreter({this.pixelsPerWorldUnit = 40.0});

  final double pixelsPerWorldUnit;

  // World units of the quad `osc` paints on; sized to fill the stage camera.
  static const double _oscPlaneSize = 24.0;

  // Keeps the oscillator behind the shapes drawn at the origin plane.
  static const double _oscPlaneDepthOffset = -0.01;

  final List<OscMaterial> _animatedMaterials = [];

  @override
  List<OscMaterial> takeAnimatedMaterials() {
    final drained = List<OscMaterial>.of(_animatedMaterials);
    _animatedMaterials.clear();
    return drained;
  }

  @override
  DslResult<Node> interpret(ShapeCommand command) {
    switch (command.type) {
      case ShapeType.circle:
        return _circle(command);
      case ShapeType.rect:
        return _rect(command);
      case ShapeType.osc:
        return _osc(command);
      case ShapeType.rotate:
        return _rotate(command);
    }
  }

  DslResult<Node> _circle(ShapeCommand command) {
    final args = command.numericArgs;
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
    final args = command.numericArgs;
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

  DslResult<Node> _osc(ShapeCommand command) {
    final args = command.numericArgs;
    if (args.length != 3) {
      return DslResult.error(
        'osc(...) expects exactly three arguments: frequency, sync, offset.',
        source: '$command',
      );
    }

    if (!OscMaterial.isAvailable) {
      return DslResult.error(
        'osc(...) requires the shader bundle to be loaded.',
        source: '$command',
      );
    }

    final material = OscMaterial(
      frequency: args[0],
      sync: args[1],
      offset: args[2],
    );
    _animatedMaterials.add(material);

    return DslResult.ok(
      Node(
        mesh: Mesh(
          PlaneGeometry(width: _oscPlaneSize, depth: _oscPlaneSize),
          material,
        ),
        localTransform: vm.Matrix4.translationValues(
          0,
          _oscPlaneDepthOffset,
          0,
        ),
      ),
    );
  }

  DslResult<Node> _rotate(ShapeCommand command) {
    final args = command.numericArgs;
    if (args.length != 1) {
      return DslResult.error(
        'rotate(angle,shape) expects exactly one numeric angle.',
        source: '$command',
      );
    }

    if (command.commandArgs.length != 1) {
      return DslResult.error(
        'rotate(angle,shape) expects exactly one nested shape command.',
        source: '$command',
      );
    }

    final innerNode = interpret(command.commandArgs.first);
    if (!innerNode.isOk || innerNode.value == null) {
      return innerNode.mapErrors<Node>();
    }

    final wrapper = Node(
      localTransform: vm.Matrix4.identity()..rotateY(vm.radians(args.first)),
    );
    wrapper.add(innerNode.value!);
    return DslResult.ok(wrapper);
  }
}
