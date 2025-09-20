import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:translator/translator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';


class CamRealScreen extends StatefulWidget {
  const CamRealScreen({super.key});

  @override
  State<CamRealScreen> createState() => _CamRealScreenState();
}

class _CamRealScreenState extends State<CamRealScreen> {
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String _realtimeText = '';
  String _realtimeTranslatedText = '';
  bool _isRealtimeTranslating = false;
  final TextRecognizer _textRecognizer = TextRecognizer();
  final GoogleTranslator _translator = GoogleTranslator();
  bool _isVietnameseToEnglish = true; // Cho phép chuyển hướng dịch

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(_cameras![0], ResolutionPreset.medium, enableAudio: false);
      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
      _startRealtimeTextRecognition();
    }
  }

  void _startRealtimeTextRecognition() {
    if (_cameraController == null) return;
    _cameraController!.startImageStream((CameraImage image) async {
      if (_isRealtimeTranslating) return;
      _isRealtimeTranslating = true;
      try {
        // Chuyển CameraImage sang InputImage (MLKit 0.13.x expects InputImageMetadata)
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();
        final camera = _cameras![0];
        final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
        final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;
        final metadata = InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes.first.bytesPerRow,
        );
        final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);

        setState(() {
          _realtimeText = 'Đang nhận diện...';
          _realtimeTranslatedText = '';
        });

        final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
        String text = recognizedText.text.trim();
        setState(() {
          _realtimeText = text.isNotEmpty ? text : '(Không nhận diện được văn bản)';
        });

        if (text.isNotEmpty) {
          String fromLang = _isVietnameseToEnglish ? 'vi' : 'en';
          String toLang = _isVietnameseToEnglish ? 'en' : 'vi';
          try {
            Translation translation = await _translator.translate(text, from: fromLang, to: toLang);
            setState(() {
              _realtimeTranslatedText = translation.text;
            });
          } catch (e) {
            setState(() {
              _realtimeTranslatedText = 'Lỗi dịch: $e';
            });
          }
        } else {
          setState(() {
            _realtimeTranslatedText = '';
          });
        }
      } catch (e) {
        setState(() {
          _realtimeText = 'Lỗi nhận diện: $e';
          _realtimeTranslatedText = '';
        });
      } finally {
        _isRealtimeTranslating = false;
      }
    });
  }

  @override
  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Realtime Dịch'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _isCameraInitialized && _cameraController != null
                ? AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  )
                : const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Văn bản nhận diện:', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isVietnameseToEnglish = !_isVietnameseToEnglish;
                              _realtimeTranslatedText = '';
                            });
                          },
                          icon: const Icon(Icons.swap_horiz),
                          label: Text(_isVietnameseToEnglish ? 'VI → EN' : 'EN → VI'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_realtimeText, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    const Text('Kết quả dịch:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_realtimeTranslatedText, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
