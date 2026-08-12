import 'package:dondon_live_coding/core/dsl.dart';
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
  String? _error;
  double _radius = 0;

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
    try {
      final radius = await runCircleScript(circleScriptSource);

      _scene.removeAll();

      // Map DSL radius to world-space units to keep the circle in view.
      final worldRadius = radius / 40.0;
      final discNode = Node(
        mesh: Mesh(
          DiscGeometry(radius: worldRadius, segments: 96),
          UnlitMaterial()..baseColorFactor = vm.Vector4(0.2, 0.25, 1.0, 1.0),
        ),
        localTransform: vm.Matrix4.identity(),
      );
      _scene.add(discNode);

      if (!mounted) {
        return;
      }

      setState(() {
        _radius = radius;
        _error = null;
      });
    } catch (e) {
      _log.severe('Failed to render circle from DSL in SceneView', e);
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '$e';
      });
    }
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
                    ? 'SceneView circle radius: ${_radius.toStringAsFixed(1)}\nEdit circleScriptSource in lib/core/dsl.dart and hot reload.'
                    : 'DSL error: $_error',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
