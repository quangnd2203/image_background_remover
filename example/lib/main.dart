import 'dart:ui' as ui;

import 'package:example/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_remover/flutter_background_remover.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});
  final ValueNotifier<ui.Image?> outImg = ValueNotifier<ui.Image?>(null);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Remover'),
      ),
      body: ValueListenableBuilder(
        valueListenable: ImagePickerService.pickedFile,
        builder: (context, image, _) {
          return GestureDetector(
            onTap: () async {
              await ImagePickerService.pickImage();
            },
            child: Container(
              alignment: Alignment.center,
              child: image == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          size: 100,
                        ),
                        Text('No image selected.'),
                      ],
                    )
                  : Column(
                      children: [
                        Image.file(image),
                        const SizedBox(
                          height: 20,
                        ),
                        TextButton(
                          onPressed: () async {
                            outImg.value = await BackgroundRemover.instance
                                .removeBg(image.readAsBytesSync());
                          },
                          child: const Text('Remove Background'),
                        ),
                        ValueListenableBuilder(
                          valueListenable: outImg,
                          builder: (context, img, _) {
                            return img == null
                                ? const SizedBox()
                                : FutureBuilder(
                                    future: img
                                        .toByteData(
                                            format: ui.ImageByteFormat.png)
                                        .then((value) =>
                                            value!.buffer.asUint8List()),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      } else if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        return Image.memory(snapshot.data!);
                                      } else {
                                        return const Text('Error');
                                      }
                                    },
                                  );
                          },
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
