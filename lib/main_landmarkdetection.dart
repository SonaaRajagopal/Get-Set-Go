import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_service.dart'; // Ensure this file exists with the proper implementation
import 'model_service.dart'; // Ensure this file exists with the proper implementation

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Landmark Classification',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: ImageClassificationPage(cameras: cameras),
    );
  }
}

class ImageClassificationPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ImageClassificationPage({super.key, required this.cameras});

  @override
  State<ImageClassificationPage> createState() =>
      _ImageClassificationPageState();
}

class _ImageClassificationPageState extends State<ImageClassificationPage> {
  late CameraService _cameraService;
  late ModelService _modelService;
  String _classificationResult = "Not detected";
  List<ClassificationResult> _recentResults = [];
  bool _isProcessing = false;
  final double _confidenceThreshold = 0.09;

  @override
  void initState() {
    super.initState();
    _cameraService = CameraService(onImageStream: classifyCameraImage);
    _modelService = ModelService();
    initializeServices();
  }

  Future<void> initializeServices() async {
    try {
      await _modelService.loadModel();
      await _modelService.loadLabels();
      await _cameraService.initializeCamera(widget.cameras);
    } catch (e) {
      setState(() {
        _classificationResult =
            "Error: Failed to initialize. Please restart the app.";
      });
    }
  }

  ClassificationResult _getMajorityResult() {
    if (_recentResults.isEmpty) {
      return ClassificationResult('Not detected', 0.0);
    }

    Map<String, int> labelCounts = {};
    Map<String, double> labelConfidences = {};

    for (var result in _recentResults) {
      labelCounts[result.label] = (labelCounts[result.label] ?? 0) + 1;
      labelConfidences[result.label] =
          (labelConfidences[result.label] ?? 0) + result.confidence;
    }

    String majorityLabel =
        labelCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    double avgConfidence =
        labelConfidences[majorityLabel]! / labelCounts[majorityLabel]!;

    return ClassificationResult(majorityLabel, avgConfidence);
  }

  Future<void> classifyCameraImage(CameraImage image) async {
    if (!_modelService.isModelLoaded || _isProcessing) return;

    _isProcessing = true;
    try {
      final input = await _cameraService.preprocessCameraImage(image);
      if (input != null) {
        final result = _modelService.classifyImage(input);
        _recentResults.add(result);
        if (_recentResults.length > 5) _recentResults.removeAt(0);

        final majorityResult = _getMajorityResult();

        setState(() {
          if (majorityResult.confidence >= _confidenceThreshold) {
            _classificationResult = majorityResult.label;
          } else {
            _classificationResult = "Not detected";
          }
        });
      }
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Landmark Classification'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _cameraService.isCameraInitialized
                ? CameraPreview(_cameraService.cameraController)
                : const Center(child: CircularProgressIndicator()),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              _classificationResult,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _modelService.dispose();
    super.dispose();
  }
}
