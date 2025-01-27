import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

class BackgroundRemoverService {
  BackgroundRemoverService._internal();

  static final BackgroundRemoverService _instance =
      BackgroundRemoverService._internal();

  static BackgroundRemoverService get instance => _instance;

  OrtSession? _session;

  Future<void> initializeOrt() async {
    try {
      OrtEnv.instance.init();
      await _createSession();
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> _createSession() async {
    try {
      final sessionOptions = OrtSessionOptions();
      const assetFileName = 'assets/u2netp.onnx';
      final rawAssetFile = await rootBundle.load(assetFileName);
      final bytes = rawAssetFile.buffer.asUint8List();
      _session = OrtSession.fromBuffer(bytes, sessionOptions);
      if (kDebugMode) {
        log('ONNX session created successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        log('Error creating ONNX session: $e');
      }
    }
  }

  Future<ui.Image> removeBg(Uint8List imageBytes) async {
    if (_session == null) {
      throw Exception("ONNX session not initialized");
    }

    /// Decode image and resize
    final originalImage = await decodeImageFromList(imageBytes);
    log('Original image size: ${originalImage.width}x${originalImage.height}');
    final resizedImage = await _resizeImage(originalImage, 320, 320);

    /// Convert image to tensor
    final rgbFloats = await _imageToFloatTensor(resizedImage);
    final inputTensor = OrtValueTensor.createTensorWithDataList(
      Float32List.fromList(rgbFloats),
      [1, 3, 320, 320],
    );

    /// Prepare inputs and run inference
    final inputs = {'input.1': inputTensor};
    final runOptions = OrtRunOptions();
    final outputs = await _session!.runAsync(runOptions, inputs);
    inputTensor.release();
    runOptions.release();

    /// Convert output tensor to an image
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

  Future<List<double>> _imageToFloatTensor(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception("Failed to get image ByteData");
    final rgbaBytes = byteData.buffer.asUint8List();
    final pixelCount = image.width * image.height;
    final floats = List<double>.filled(pixelCount * 3, 0);

    // Normalization of mask
    for (int i = 0; i < pixelCount; i++) {
      floats[i] = rgbaBytes[i * 4] / 255.0; // Red
      floats[pixelCount + i] = rgbaBytes[i * 4 + 1] / 255.0; // Green
      floats[2 * pixelCount + i] = rgbaBytes[i * 4 + 2] / 255.0; // Blue
    }
    return floats;
  }
}
