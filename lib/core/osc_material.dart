// Architecture: back end of the DSL pipeline — renderer adapter for `osc`.
//
// A `ShaderMaterial` bound to the `OscFragment` shader. The DSL supplies the
// static parameters; the stage pushes elapsed time every frame, so the uniform
// block is repacked rather than the node rebuilt.

import 'package:dondon_live_coding/shaders.dart';
import 'package:flutter_scene/scene.dart';

class OscMaterial extends ShaderMaterial {
  OscMaterial({
    required this.frequency,
    required this.sync,
    required this.offset,
  }) : super(fragmentShader: oscFragmentShader!) {
    updateTime(0);
  }

  static bool get isAvailable => oscFragmentShader != null;

  final double frequency;
  final double sync;
  final double offset;

  void updateTime(double seconds) {
    setUniformBlockFromFloats('OscInfo', [frequency, sync, offset, seconds]);
  }
}
