import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;

Future<gpu.Texture> loadGpuTextureFromAsset(String assetPath) async {
  // 1. Load the asset data
  final ByteData data = await rootBundle.load(assetPath);

  // 2. Decode the data into a ui.Image
  final ui.Codec codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
  );
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  final ui.Image image = frameInfo.image;

  // 3. Extract the raw, uncompressed RGBA8888 byte data
  final ByteData? rgbaBytes = await image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  );
  if (rgbaBytes == null) {
    throw Exception("Failed to extract raw bytes from image: $assetPath");
  }

  // 4. Allocate a texture in Flutter GPU memory
  // Note: StorageMode must be hostVisible to allow CPU-to-GPU byte copies via overwrite()
  final gpu.Texture texture = gpu.gpuContext.createTexture(
    gpu.StorageMode.hostVisible,
    image.width,
    image.height,
    format: gpu.PixelFormat.r8g8b8a8UNormInt,
    enableShaderReadUsage: true,
  );

  // 5. Push the raw bytes directly to the GPU texture
  texture.overwrite(rgbaBytes);

  // Clean up the ui.Image handle now that it's copied to GPU VRAM
  image.dispose();

  return texture;
}
