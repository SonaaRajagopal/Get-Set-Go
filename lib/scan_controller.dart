import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'dart:developer';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ScanController extends GetxController {
  late CameraController cameraController;
  late List<CameraDescription> cameras;
  var isCameraInitialized = false.obs;
  var cameraCount = 0;
  late Interpreter interpreter;
  var isModelLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    initCamera();
    loadModel();
  }

  @override
  void dispose() {
    cameraController.dispose();
    interpreter.close();
    super.dispose();
  }

  Future<void> initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();
      cameraController = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await cameraController.initialize().then((value) {
        cameraController.startImageStream((image) {
          cameraCount++;
          if (cameraCount % 10 == 0) {
            cameraCount = 0;
            processImage(image);
          }
          update();
        });
      });
      isCameraInitialized.value = true;
      update();
    } else {
      log("Camera permission denied");
    }
  }

  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset('assets/your_model.tflite');
      isModelLoaded.value = true;
      log("Model loaded successfully");
    } catch (e) {
      log("Failed to load model: $e");
    }
  }

  void processImage(CameraImage image) {
    if (!isModelLoaded.value) return;

    var img = convertYUV420ToImage(image);
    var inputImage = img.getBytes();
    
    // Prepare input data (modify as per your model's requirements)
    var input = inputImage.buffer.asFloat32List();

    // Prepare output tensor (modify as per your model's output shape)
    var output = List.filled(1 * 1001, 0).reshape([1, 1001]);

    // Run inference
    interpreter.run(input, output);

    // Process the output (modify as per your needs)
    var results = output[0] as List<double>;
    var maxScore = results.reduce((a, b) => a > b ? a : b);
    var maxIndex = results.indexOf(maxScore);

    log("Detected class: $maxIndex with confidence: $maxScore");
  }

  img.Image convertYUV420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    final yRowStride = cameraImage.planes[0].bytesPerRow;
    final uvRowStride = cameraImage.planes[1].bytesPerRow;
    final uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    final image = img.Image(width, height);

    for (var w = 0; w < width; w++) {
      for (var h = 0; h < height; h++) {
        final uvIndex =
            uvPixelStride * (w / 2).floor() + uvRowStride * (h / 2).floor();
        final index = h * width + w;
        final yIndex = h * yRowStride + w;

        final y = cameraImage.planes[0].bytes[yIndex];
        final u = cameraImage.planes[1].bytes[uvIndex];
        final v = cameraImage.planes[2].bytes[uvIndex];

        image.data[index] = yuv2rgb(y, u, v);
      }
    }
    return image;
  }

  int yuv2rgb(int y, int u, int v) {
    // Convert YUV to RGB
    var r = (y + v * 1436 / 1024 - 179).round();
    var g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
    var b = (y + u * 1814 / 1024 - 227).round();

    // Clipping RGB values to be inside [0, 255]
    r = r.clamp(0, 255);
    g = g.clamp(0, 255);
    b = b.clamp(0, 255);

    return 0xFF000000 | (b << 16) | (g << 8) | r;
  }
}