import 'package:data_assets/data_assets.dart';
import 'package:dondon_live_coding/core/logger.dart';
import 'package:flutter_gpu_shaders/build.dart';
import 'package:flutter_scene/build_hooks.dart';
import 'package:hooks/hooks.dart';

final _log = AppLogger.get('hook.build');

void main(List<String> args) async {
  AppLogger.configure(emitToStdout: true);

  await build(args, (input, output) async {
    // Check if the current toolchain environment has data assets turned on
    if (input.config.buildDataAssets) {
      _log.info('Dart Data Assets are ON');
    } else {
      _log.info('Dart Data Assets are OFF');
    }

    // flutter_scene:init:start
    // Prefer Dart DataAssets when available; fall back to legacy assets.
    buildScenes(
      buildInput: input,
      buildOutput: output,
      assetMode: SceneAssetMode.dataAssetsIfAvailable,
    );
    // Prefer Dart DataAssets when available; fall back to legacy assets.
    await buildMaterials(
      buildInput: input,
      buildOutput: output,
      assetMode: MaterialAssetMode.dataAssetsIfAvailable,
    );
    // Prefer Dart DataAssets when available; fall back to legacy assets.
    await buildShaderBundleJson(
      buildInput: input,
      buildOutput: output,
      manifestFileName: 'my_renderer.shaderbundle.json',
      assetMode: ShaderBundleAssetMode.dataAssetsIfAvailable,
    );
    // flutter_scene:init:end
  });
}
