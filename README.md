# Flutter Background Remover

A Flutter package that removes the background from images using an ONNX model. The package provides a seamless way to perform image processing, leveraging the power of machine learning through ONNX Runtime.

---

## 🌟 Features

- Remove the background from images with high accuracy.
- Lightweight and efficient implementation.
- Easy integration with your Flutter project.

---

<img src="https://github.com/Netesh5/flutter_background_remover/main/overview.gif?raw=true" alt="Screenshot" width="300" height="600" />


## Getting Started

### 🚀 Prerequisites

Before using this package, ensure that the following dependencies are included in your `pubspec.yaml`:

```yaml
dependencies:
  flutter_background_remover: ^latest_version
  ```

##  Usage
# Initialization
Before using the `removeBg` method, you must initialize the ONNX environment:

    ```
    import 'package:flutter_background_remover/flutter_background_remover.dart';

    @override
    void initState() {
        super.initState();
        BackgroundRemover.instance.initializeOrt();
    }

    ```

# Remove Background
To remove the background from an image:
```
import 'dart:typed_data';
import 'package:flutter_background_remover/flutter_background_remover.dart';

Uint8List imageBytes = /* Load your image bytes */;
ui.Image resultImage = await BackgroundRemover.instance.removeBg(imageBytes);

```

## API

### Methods

| Method                  | Description                                                                 | Parameters                      | Returns                           |
|-------------------------|-----------------------------------------------------------------------------|---------------------------------|-----------------------------------|
| `initializeOrt()`       | Initializes the ONNX runtime environment. Call this method once before using `removeBg`. | None                            | `Future<void>`                   |
| `removeBg(Uint8List imageBytes)` | Removes the background from an image.                                     | `imageBytes` - The image in byte array format. | `Future<ui.Image>` - The processed image with the background removed. |


## 🔗 Contributing
Contributions are welcome! If you encounter any issues or have suggestions for improvements, feel free to create an issue or submit a pull request.