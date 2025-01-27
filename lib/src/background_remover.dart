import 'package:flutter/material.dart';
import 'package:flutter_background_remover/flutter_background_remover.dart';

class BackgroundRemover extends StatefulWidget {
  const BackgroundRemover({super.key});

  @override
  State<BackgroundRemover> createState() => _BackgroundRemoverState();
}

class _BackgroundRemoverState extends State<BackgroundRemover> {
  @override
  void initState() {
    BackgroundRemoverService.instance.initializeOrt();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
