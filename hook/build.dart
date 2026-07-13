import 'package:flutter_scene/build_hooks.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    // flutter_scene:init:start
    // Import .glb scenes under assets/ as DataAssets, loadable by source path
    // with loadScene (and hot-reloadable). A no-op when there are no scenes.
    buildScenes(
      buildInput: input,
      buildOutput: output,
      assetMode: SceneAssetMode.dataAssetsRequired,
    );
    // Compile .fmat materials under assets/ as DataAssets, loadable by source
    // path with loadFmatMaterial (and hot-reloadable). A no-op when there are
    // no materials.
    await buildMaterials(
      buildInput: input,
      buildOutput: output,
      assetMode: MaterialAssetMode.dataAssetsRequired,
    );
    // flutter_scene:init:end
  });
}

// Copy into: hook/build.dart

// import 'package:flutter_gpu_shaders/build.dart';
// import 'package:hooks/hooks.dart';

// void main(List<String> args) async {
//   await build(args, (input, output) async {
//     await buildShaderBundleJson(
//       buildInput: input,
//       buildOutput: output,
//       manifestFileName: 'my_renderer.shaderbundle.json',
//     );
//   });
// }
