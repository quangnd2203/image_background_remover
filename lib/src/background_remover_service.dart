import 'dart:developer';

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
      log('ORT Session created', name: "BackgroundRemoverService");
    } catch (e) {
      log(e.toString());
    }
  }
}
