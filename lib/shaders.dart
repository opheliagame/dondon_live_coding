// Architecture: host layer — compiled shader bundle access.
//
// The DSL interpreter maps commands to nodes synchronously, so the bundle is
// loaded once at boot and its shaders are cached here for synchronous lookup.
// A missing bundle is logged, never thrown, so the shapes that do not need a
// custom shader keep rendering.

import 'package:dondon_live_coding/core/logger.dart';
import 'package:flutter_scene/gpu.dart' as gpu;

const String _kShaderBundlePath =
    'build/shaderbundles/my_renderer.shaderbundle';
// NOTE: If you're building a library, the path must be prefixed
//       with a package name. For example:
//      'packages/my_cool_renderer/build/shaderbundles/my_renderer.shaderbundle'

final _log = AppLogger.get('app.shaders');

gpu.ShaderLibrary? _shaderLibrary;

Future<void> loadShaderBundle() async {
  if (_shaderLibrary != null) {
    return;
  }

  final library = await gpu.loadShaderLibraryAsync(_kShaderBundlePath);
  if (library == null) {
    _log.severe('Failed to load shader bundle! ($_kShaderBundlePath)');
    return;
  }

  _shaderLibrary = library;
}

gpu.Shader? get oscFragmentShader => _shaderLibrary?['OscFragment'];
