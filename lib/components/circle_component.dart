// Architecture: component layer — draw-only shape widget.
//
// This component receives an already-populated Scene and only decides camera
// framing for circle-like content. DSL evaluation and mapping stay in runtime.

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

class CircleComponent extends StatelessWidget {
  const CircleComponent({required this.scene, super.key});

  final Scene scene;

  @override
  Widget build(BuildContext context) {
    return SceneView(
      scene,
      camera: PerspectiveCamera(
        position: vm.Vector3(0, 6, 0),
        target: vm.Vector3(0, 0, 0),
        up: vm.Vector3(0, 0, -1),
      ),
    );
  }
}
