import 'package:dondon_live_coding/core/dsl.dart';
import 'package:dondon_live_coding/core/dsl_result.dart';
import 'package:dondon_live_coding/core/interpreter.dart';
import 'package:dondon_live_coding/core/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

final _log = AppLogger.get('app.main');

void main() async {
  AppLogger.configure();
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Scene.initializeStaticResources();
  } catch (e) {
    if (kDebugMode) {
      _log.severe('Failed to initialize Flutter Scene resources', e);
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: SafeArea(child: CircleDslPreview())),
    );
  }
}

class CircleDslPreview extends StatelessWidget {
  const CircleDslPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircleSceneView();
  }
}

class CircleSceneView extends StatefulWidget {
  const CircleSceneView({super.key});

  @override
  State<CircleSceneView> createState() => _CircleSceneViewState();
}

class _CircleSceneViewState extends State<CircleSceneView> {
  final Scene _scene = Scene();
  final DslInterpreter _interpreter = const ShapeCommandInterpreter();
  DslError? _error;
  String _shapeCommand = 'none';

  @override
  void initState() {
    super.initState();
    _loadSceneFromDsl();
  }

  @override
  void reassemble() {
    super.reassemble();
    _loadSceneFromDsl();
  }

  Future<void> _loadSceneFromDsl() async {
    final script = await runCircleScript(circleScriptSource);
    if (_reportIfFailed(script)) {
      return;
    }

    final parsed = ShapeCommand.parse(script.value!);
    if (_reportIfFailed(parsed)) {
      return;
    }

    final node = _interpreter.interpret(parsed.value!);
    if (_reportIfFailed(node)) {
      return;
    }

    _scene.removeAll();
    _scene.add(node.value!);

    if (!mounted) {
      return;
    }

    setState(() {
      _shapeCommand = '${parsed.value}';
      _error = null;
    });
  }

  /// Leaves the current scene untouched and surfaces the oldest error.
  bool _reportIfFailed(DslResult<Object?> result) {
    final error = result.firstError;
    if (error == null) {
      return false;
    }

    _log.severe('DSL error: $error');
    if (mounted) {
      setState(() {
        _error = error;
      });
    }
    return true;
  }

  @override
  void dispose() {
    _scene.removeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SceneView(
          _scene,
          camera: PerspectiveCamera(
            position: vm.Vector3(0, 6, 0),
            target: vm.Vector3(0, 0, 0),
            up: vm.Vector3(0, 0, -1),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error == null
                    ? 'SceneView shape: $_shapeCommand\nEdit circleScriptSource in lib/core/dsl.dart and hot reload.'
                    : 'DSL error: ${_error!.message}\nStill showing: $_shapeCommand',
                style: TextStyle(
                  color: _error == null ? Colors.white : Colors.orangeAccent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
