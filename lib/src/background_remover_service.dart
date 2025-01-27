import 'dart:developer';

import 'package:flutter/foundation.dart';
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
}
