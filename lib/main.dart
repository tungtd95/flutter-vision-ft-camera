import 'package:camera/camera.dart';
import 'package:camera_flutter/scanner_utils.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(CameraApp());
}

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  CameraController controller;
  bool _isDetecting = false;
  String barcodes = "";
  int index = 0;

  @override
  void initState() {
    super.initState();
    _initCam();
  }

  void _initCam() async {
    final CameraDescription description =
        await ScannerUtils.getCamera(CameraLensDirection.back);
    controller = CameraController(description, ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream((image) {
        if (_isDetecting) return;
        _isDetecting = true;
        ScannerUtils.detect(
          image: image,
          imageRotation: description.sensorOrientation,
        ).then(
          (List<Barcode> results) {
            results.forEach((element) {
              setState(() {
                index++;
                if (index % 15 == 0) barcodes = "";
                barcodes += "$index. ${element.displayValue}\n";
              });
            });
          },
        ).whenComplete(() => _isDetecting = false);
      });
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return Column(
      children: [
        Container(
          width: 200,
          height: 200 / controller.value.aspectRatio,
          child: CameraPreview(controller),
        ),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              barcodes,
              style: TextStyle(color: Colors.white),
            ),
          ),
        )
      ],
    );
  }
}
