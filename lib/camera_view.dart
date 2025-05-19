import 'package:flutter/material.dart';
import 'scan_controller.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';

class CameraView extends StatelessWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<ScanController>(
        init: ScanController(),
        builder: (controller) {
          return controller.isCameraInitialized.value
              ? SizedBox.expand(
            child: CameraPreview(controller.cameraController),
          )
              : const Center(child: Text("Loading Preview"));
        },
      ),
    );
  }
}
