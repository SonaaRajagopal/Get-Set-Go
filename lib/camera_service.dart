// camera_service.dart
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class CameraService {
  late CameraController _cameraController;
  final Function(CameraImage) onImageStream;
  bool isCameraInitialized = false;

  CameraService({required this.onImageStream});

  CameraController get cameraController => _cameraController;

  Future<void> initializeCamera(List<CameraDescription> cameras) async {
    // Select the back camera if available
    final camera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController.initialize();

    try {
      await _cameraController.lockCaptureOrientation();
      await _cameraController.setExposureMode(ExposureMode.auto);
      await _cameraController.setFocusMode(FocusMode.auto);
    } catch (e) {
      debugPrint('Failed to set camera parameters: $e');
    }

    isCameraInitialized = true;

    await _cameraController.startImageStream((image) {
      try {
        onImageStream(image);
      } catch (e) {
        debugPrint('Error in image stream: $e');
      }
    });
  }

  Future<List<List<List<List<double>>>>?> preprocessCameraImage(
      CameraImage image) async {
    final img.Image convertedImage = _convertYUV420toImageColor(image);

    // Apply image enhancement
    var enhancedImage = img.adjustColor(
      convertedImage,
      contrast: 1.1,
      saturation: 1.2,
    );

    // Center crop the image to square
    enhancedImage = _centerCrop(enhancedImage);

    // Resize to model input size
    final img.Image resizedImage = img.copyResize(
      enhancedImage,
      width: 224,
      height: 224,
      interpolation: img.Interpolation.cubic,
    );

    final input = List.generate(
      1,
      (i) => List.generate(
        224,
        (j) => List.generate(
          224,
          (k) => List.filled(3, 0.0),
        ),
      ),
    );

    // Normalize pixel values using ImageNet mean and std
    const mean = [0.485, 0.456, 0.406];
    const std = [0.229, 0.224, 0.225];

    for (int x = 0; x < 224; x++) {
      for (int y = 0; y < 224; y++) {
        final pixel = resizedImage.getPixel(x, y);
        input[0][x][y][0] = ((img.getRed(pixel) / 255.0) - mean[0]) / std[0];
        input[0][x][y][1] = ((img.getGreen(pixel) / 255.0) - mean[1]) / std[1];
        input[0][x][y][2] = ((img.getBlue(pixel) / 255.0) - mean[2]) / std[2];
      }
    }

    return input;
  }

  img.Image _centerCrop(img.Image image) {
    final size = math.min(image.width, image.height);
    final x = (image.width - size) ~/ 2;
    final y = (image.height - size) ~/ 2;
    return img.copyCrop(
        image, x, y, size, size); // Updated to use positional parameters
  }

  img.Image _convertYUV420toImageColor(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image rgbImage = img.Image(width, height);

    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
        final int index = y * width + x;

        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];

        // Convert YUV to RGB
        int r = (yp + (1.370705 * (vp - 128))).toInt().clamp(0, 255);
        int g = (yp - (0.698001 * (vp - 128)) - (0.337633 * (up - 128)))
            .toInt()
            .clamp(0, 255);
        int b = (yp + (1.732446 * (up - 128))).toInt().clamp(0, 255);

        // Use setPixel instead of setPixelRgb
        rgbImage.setPixel(x, y, img.getColor(r, g, b));
      }
    }

    return rgbImage;
  }

  Future<void> dispose() async {
    try {
      await _cameraController.stopImageStream();
      await _cameraController.dispose();
    } catch (e) {
      debugPrint('Error disposing camera: $e');
    }
  }
}
