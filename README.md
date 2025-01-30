# Image Background Remover - Flutter

A Flutter package that removes the background from images using an ONNX model. The package provides a seamless way to perform image processing, leveraging the power of machine learning through ONNX Runtime.

---

## 🌟 Features

- Remove the background from images with high accuracy.
- Works entirely offline, ensuring privacy and reliability.  
- Lightweight and optimized for efficient performance.  
- Simple and seamless integration with Flutter projects. 

---

## 🔭 Overview
<img src="https://github.com/user-attachments/assets/a306cec8-82eb-482a-92d4-d5d99603aebc" alt="Overview" width="300" height="600" />


## Getting Started

### 🚀 Prerequisites

Before using this package, ensure that the following dependencies are included in your `pubspec.yaml`:

```yaml
dependencies:
  image_background_remover: ^latest_version
  ```

##  Usage
# Initialization
Before using the `removeBg` method, you must initialize the ONNX environment:
    ```
    import 'package:image_background_remover/image_background_remover.dart';

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
import 'package:image_background_remover/image_background_remover.dart';

Uint8List imageBytes = /* Load your image bytes */;
ui.Image resultImage = await BackgroundRemover.instance.removeBg(imageBytes);
/* resultImage will contain image with transparent background*/


```

## API

### Methods

| Method                  | Description                                                                 | Parameters                      | Returns                           |
|-------------------------|-----------------------------------------------------------------------------|---------------------------------|-----------------------------------|
| `initializeOrt()`       | Initializes the ONNX runtime environment. Call this method once before using `removeBg`. | None                            | `Future<void>`                   |
| `removeBg(Uint8List imageBytes)` | Removes the background from an image.                                     | `imageBytes` - The image in byte array format. | `Future<ui.Image>` - The processed image with the background removed. |


## ⚠️ Warning

This package uses an offline model to process images, which is bundled with the application. **This may increase the size of your app** depending on the size of the model file. 

### Recommendations:
- Ensure your app has sufficient storage capacity for the increased size.
- Regularly optimize your app's assets and resources to minimize its footprint.



## 🔗 Contributing
Contributions are welcome! If you encounter any issues or have suggestions for improvements, feel free to create an issue or submit a pull request.