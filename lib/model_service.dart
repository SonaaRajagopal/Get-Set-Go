import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class ClassificationResult {
  final String label;
  final double confidence;

  ClassificationResult(this.label, this.confidence);
}

class ModelService {
  late Interpreter _interpreter;
  bool isModelLoaded = false;
  List<String> _labels = [];

  Future<void> loadModel() async {
    try {
      // Use XNNPACK delegate for better performance on CPU
      final options = InterpreterOptions()..addDelegate(XNNPackDelegate());

      _interpreter = await Interpreter.fromAsset(
        'assets/saved_landmark_model_1.tflite',
        options: options,
      );

      isModelLoaded = true;
      printModelInfo(); // Print model info for debugging
    } catch (e) {
      print('Error loading model: $e');
      rethrow;
    }
  }

  Future<void> loadLabels() async {
    try {
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData
          .split('\n')
          .where((label) => label.trim().isNotEmpty)
          .map((label) => label.trim())
          .toList();
    } catch (e) {
      print('Error loading labels: $e');
      rethrow;
    }
  }

  ClassificationResult classifyImage(List<List<List<List<double>>>> input) {
    if (!isModelLoaded) {
      return ClassificationResult('Model not loaded', 0.0);
    }

    try {
      // Prepare output tensor
      var outputShape = _interpreter.getOutputTensor(0).shape;
      var output = List.filled(outputShape[0] * outputShape[1], 0.0)
          .reshape([outputShape[0], outputShape[1]]);

      // Run inference
      _interpreter.run(input, output);

      // Apply softmax to get probabilities
      List<double> probabilities = _applySoftmax(List<double>.from(output[0]));

      // Get top prediction
      int maxIndex = 0;
      double maxProb = probabilities[0];

      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      return ClassificationResult(_labels[maxIndex], maxProb);
    } catch (e) {
      print('Error during classification: $e');
      return ClassificationResult('Error during classification', 0.0);
    }
  }

  List<double> _applySoftmax(List<double> inputs) {
    double max = inputs.reduce(math.max);
    List<double> exps = inputs.map((x) => math.exp(x - max)).toList();
    double sumExps = exps.reduce((a, b) => a + b);
    return exps.map((x) => x / sumExps).toList();
  }

  void dispose() {
    _interpreter.close();
  }

  void printModelInfo() {
    if (!isModelLoaded) {
      print('Model not loaded');
      return;
    }

    try {
      var inputTensor = _interpreter.getInputTensor(0);
      var outputTensor = _interpreter.getOutputTensor(0);

      print('Model Input Shape: ${inputTensor.shape}');
      print('Model Input Type: ${inputTensor.type}');
      print('Model Output Shape: ${outputTensor.shape}');
      print('Model Output Type: ${outputTensor.type}');
    } catch (e) {
      print('Error getting model info: $e');
    }
  }
}
