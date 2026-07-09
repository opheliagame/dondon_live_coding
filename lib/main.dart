import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold(body: FirstScene()));
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

    // A cube mesh, made from built-in geometry and an unlit material.
    final mesh = Mesh(
      CuboidGeometry(vm.Vector3(1, 1, 1), debugColors: true),
      UnlitMaterial(),
    );
    scene.add(Node(mesh: mesh));
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
