import 'dart:math';

import 'package:code_forge/code_forge.dart';
import 'package:dondon_live_coding/texture_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

void main() async {
  // 1. Ensure Flutter bindings are initialized first
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Load the base shader bundle required by Flutter Scene
    await Scene.initializeStaticResources();
  } catch (e) {
    if (kDebugMode) {
      print("Failed to initialize Flutter Scene resources: $e");
    }
  }

  // init CodeForge
  await RustLib.init();

  // 3. Now it's safe to run your app and build 3D objects
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // return const MaterialApp(home: Scaffold(body: FirstScene()));

    return MaterialApp(
      home: Scaffold(
        body: CodeForge(
          // language: Mode(), // Defaults to Mode(), means plain text
          // editorTheme: {"atomOneDarkTheme": }, // Defaults to lightFlairTheme
        ),
      ),
    );
  }
}

class FirstScene extends StatefulWidget {
  const FirstScene({super.key});

  @override
  State<FirstScene> createState() => _FirstSceneState();
}

class _FirstSceneState extends State<FirstScene> {
  // Constructing a Scene starts loading the engine's shared resources.
  final Scene scene = Scene();

  @override
  void initState() {
    super.initState();
    _load();
  }

  // The scene hot reloads in place: loadScene patches a re-exported GLB into
  // this node automatically, and the logo holds only the root, so no reload
  // callback is needed.
  Future<void> _load() async {
    // A cube mesh, made from built-in geometry and an unlit material.
    final mesh = Mesh(
      CuboidGeometry(vm.Vector3(1, 1, 1), debugColors: true),
      UnlitMaterial(),
    );

    final material = PhysicallyBasedMaterial()
      ..baseColorFactor =
          vm.Vector4(1, 1, 1, 1.0) // linear RGBA
      ..metallicFactor =
          0 // 0 = dielectric, 1 = metal
      ..roughnessFactor = 0; // 0 = mirror, 1 = fully diffuse

    // Load the texture using our helper function
    loadGpuTextureFromAsset('assets/textures/Teamlab_logo.png').then(
      (myTexture) => {
        // Set the texture to the base color (albedo) slot
        material.baseColorTexture = myTexture,
      },
    );

    final spheremesh = Mesh(SphereGeometry(radius: 1), material);

    // final node = Node(mesh: mesh)..addComponent(SpinComponent(1.5));
    // scene.add(node);

    // final node2 = Node(mesh: spheremesh)..addComponent(SpinComponent(1.5));
    // scene.add(node2);

    // models
    final model = await loadScene('assets/models/nonkus.glb');
    scene.add(model);
  }

  @override
  void dispose() {
    // Optional: the scene is dropped with this State. `Node.fromAsset` caches
    // the imported model template (shared across clones), so its GPU resources
    // persist for the session regardless.
    scene.removeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SceneView(
      scene,
      // The camera orbits the origin once per second.
      cameraBuilder: (elapsed) {
        final t = elapsed.inMicroseconds / 1e6;
        return PerspectiveCamera(
          position: vm.Vector3(sin(t) * 5, 2, cos(t) * 5),
          target: vm.Vector3(0, 0, 0),
        );
      },
    );
  }
}

class SpinComponent extends Component {
  SpinComponent(this.radiansPerSecond);

  final double radiansPerSecond;

  @override
  void update(double deltaSeconds) {
    node.localTransform =
        node.localTransform *
        vm.Matrix4.rotationZ(radiansPerSecond * deltaSeconds);
  }
}
