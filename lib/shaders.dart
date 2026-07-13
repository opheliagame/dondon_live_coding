import 'package:flutter_gpu/gpu.dart' as gpu;

const String _kShaderBundlePath =
    'build/shaderbundles/my_renderer.shaderbundle';
// NOTE: If you're building a library, the path must be prefixed
//       with a package name. For example:
//      'packages/my_cool_renderer/build/shaderbundles/my_renderer.shaderbundle'

Future<gpu.ShaderLibrary?> _shaderLibrary = Future.value(null);
Future<gpu.ShaderLibrary?> get shaderLibrary {
  if (_shaderLibrary != Future.value(null)) {
    return _shaderLibrary;
  }
  _shaderLibrary = gpu.ShaderLibrary.fromAsset(_kShaderBundlePath);
  if (_shaderLibrary != Future.value(null)) {
    return _shaderLibrary;
  }

  throw Exception("Failed to load shader bundle! ($_kShaderBundlePath)");
}
