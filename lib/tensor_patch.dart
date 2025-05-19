import 'dart:typed_data';
import 'dart:collection';
import 'package:tflite_flutter/tflite_flutter.dart';

class TensorHandler {
  final Tensor _tensor;

  TensorHandler(this._tensor);

  UnmodifiableListView<int> get tensorData {
    final data = _tensor.data;
    return UnmodifiableListView(data);
  }

  // If you need to work with Uint8List specifically
  Uint8List getRawData() {
    return Uint8List.fromList(_tensor.data);
  }
}
