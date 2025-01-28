import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

class BackgroundRemover {
  BackgroundRemover._internal();

  static final BackgroundRemover _instance = BackgroundRemover._internal();

  static BackgroundRemover get instance => _instance;

  // The ONNX session used for inference.
  OrtSession? _session;

  /// Initializes the ONNX environment and creates a session.
  ///
  /// This method should be called once before using the [removeBg] method.
  Future<void> initializeOrt() async {
    try {
      /// Initialize the ONNX runtime environment.
      OrtEnv.instance.init();

      /// Create the ONNX session.
      await _createSession();
    } catch (e) {
      log(e.toString());
    }
  }

  /// Creates an ONNX session using the model from assets.
  Future<void> _createSession() async {
    try {
      /// Session configuration options.
      final sessionOptions = OrtSessionOptions();

      /// Path to the ONNX model file.
      const assetFileName =
          '/Users/neteshpaudel/Projects/flutter_background_remover/assets/model.onnx';

      /// Load the model as a raw asset.
      final rawAssetFile = await rootBundle.load(assetFileName);

      /// Convert the asset to a byte array.
      final bytes = rawAssetFile.buffer.asUint8List();

      /// Create the ONNX session.
      _session = OrtSession.fromBuffer(bytes, sessionOptions);
      if (kDebugMode) {
        log('ONNX session created successfully.', name: "BackgroundRemover");
      }
    } catch (e) {
      if (kDebugMode) {
        log('Error creating ONNX session: $e', name: "BackgroundRemover");
      }
    }
  }

  /// Removes the background from an image.
  ///
  /// - [imageBytes]: The input image as a byte array.
  /// - Returns: A [ui.Image] with the background removed.
  Future<ui.Image> removeBg(Uint8List imageBytes) async {
    if (_session == null) {
      throw Exception("ONNX session not initialized");
    }

    /// Decode the input image and resize it to the required dimensions.
    final originalImage = await decodeImageFromList(imageBytes);
    log('Original image size: ${originalImage.width}x${originalImage.height}');
    final resizedImage = await _resizeImage(originalImage, 320, 320);

    /// Convert the resized image into a tensor format required by the ONNX model.
    final rgbFloats = await _imageToFloatTensor(resizedImage);
    final inputTensor = OrtValueTensor.createTensorWithDataList(
      Float32List.fromList(rgbFloats),
      [1, 3, 320, 320],
    );

    /// Prepare the inputs and run inference on the ONNX model.
    final inputs = {'input.1': inputTensor};
    final runOptions = OrtRunOptions();
    final outputs = await _session!.runAsync(runOptions, inputs);
    inputTensor.release();
    runOptions.release();

    /// Process the output tensor and generate the final image with the background removed.
    final outputTensor = outputs?[0]?.value;
    if (outputTensor is List) {
      final mask = outputTensor[0][0];
      final resizedMask =
          resizeMask(mask, originalImage.width, originalImage.height);
      return _applyMaskToOriginalSizeImage(originalImage, resizedMask);
    } else {
      throw Exception('Unexpected output format from ONNX model.');
    }
  }

  /// Resizes the input image to the specified dimensions.
  Future<ui.Image> _resizeImage(
      ui.Image image, int targetWidth, int targetHeight) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect =
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble());
    canvas.drawImageRect(image, srcRect, dstRect, paint);

    final picture = recorder.endRecording();
    return picture.toImage(targetWidth, targetHeight);
  }

  /// Resizes the mask to match the original image dimensions.
  List resizeMask(List mask, int originalWidth, int originalHeight) {
    final resizedMask = List.generate(
      originalHeight,
      (_) => List.filled(originalWidth, 0.0),
    );

    for (int y = 0; y < originalHeight; y++) {
      for (int x = 0; x < originalWidth; x++) {
        final scaledX = x * 320 ~/ originalWidth;
        final scaledY = y * 320 ~/ originalHeight;
        resizedMask[y][x] = mask[scaledY][scaledX];
      }
    }
    return resizedMask;
  }

  /// Converts an image into a floating-point tensor.
  Future<List<double>> _imageToFloatTensor(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception("Failed to get image ByteData");
    final rgbaBytes = byteData.buffer.asUint8List();
    final pixelCount = image.width * image.height;
    final floats = List<double>.filled(pixelCount * 3, 0);

    /// Extract and normalize RGB channels.
    for (int i = 0; i < pixelCount; i++) {
      floats[i] = rgbaBytes[i * 4] / 255.0; // Red
      floats[pixelCount + i] = rgbaBytes[i * 4 + 1] / 255.0; // Green
      floats[2 * pixelCount + i] = rgbaBytes[i * 4 + 2] / 255.0; // Blue
    }
    return floats;
  }

  /// Applies the mask to the original image and generates the final output.
  Future<ui.Image> _applyMaskToOriginalSizeImage(
      ui.Image image, List resizedMask) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception("Failed to get image ByteData");

    final rgbaBytes = byteData.buffer.asUint8List();
    final pixelCount = image.width * image.height;
    final outRgbaBytes = Uint8List(4 * pixelCount);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final i = y * image.width + x;
        final maskValue = (resizedMask[y][x] * 255).clamp(0, 255).toInt();

        outRgbaBytes[i * 4] = rgbaBytes[i * 4]; // Red
        outRgbaBytes[i * 4 + 1] = rgbaBytes[i * 4 + 1]; // Green
        outRgbaBytes[i * 4 + 2] = rgbaBytes[i * 4 + 2]; // Blue
        outRgbaBytes[i * 4 + 3] = maskValue; // Alpha
      }
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        outRgbaBytes, image.width, image.height, ui.PixelFormat.rgba8888,
        (ui.Image img) {
      completer.complete(img);
    });

    return completer.future;
  }
}
