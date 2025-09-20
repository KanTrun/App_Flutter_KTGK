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
  String _lastTranslatedText = '';
  DateTime? _lastTranslateTime;
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
      // Throttle: chỉ dịch mỗi 600ms
      final now = DateTime.now();
      if (_lastTranslateTime != null && now.difference(_lastTranslateTime!).inMilliseconds < 600) return;
      _lastTranslateTime = now;
      _isRealtimeTranslating = true;
      try {
        // Chỉ xử lý nếu đúng định dạng YUV420 (Android)
        if (image.format.group != ImageFormatGroup.yuv420) {
          _isRealtimeTranslating = false;
          return;
        }
        // Chuyển CameraImage (YUV420) sang NV21
        final int width = image.width;
        final int height = image.height;
        final int uvRowStride = image.planes[1].bytesPerRow;
        final int uvPixelStride = image.planes[1].bytesPerPixel!;
        final bytes = Uint8List(width * height + (width * height) ~/ 2);
        int index = 0;
        // Y plane
        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            bytes[index++] = image.planes[0].bytes[y * image.planes[0].bytesPerRow + x];
          }
        }
        // UV planes (VU interleaved)
        for (int y = 0; y < height ~/ 2; y++) {
          for (int x = 0; x < width ~/ 2; x++) {
            int uIndex = y * uvRowStride + x * uvPixelStride;
            int vIndex = y * uvRowStride + x * uvPixelStride;
            bytes[index++] = image.planes[2].bytes[vIndex]; // V
            bytes[index++] = image.planes[1].bytes[uIndex]; // U
          }
        }
        final camera = _cameras![0];
        final metadata = InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        );
        final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);

        final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
        String text = recognizedText.text.trim();
        setState(() {
          _realtimeText = text.isNotEmpty ? text : '(Không nhận diện được văn bản)';
        });

        // Chỉ dịch nếu text khác lần trước và không rỗng
        if (text.isNotEmpty && text != _lastTranslatedText) {
          _lastTranslatedText = text;
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
                    Container(
                      constraints: const BoxConstraints(maxHeight: 80),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _realtimeText,
                          style: const TextStyle(fontSize: 16),
                          maxLines: 4,
                          minLines: 1,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Kết quả dịch:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 80),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _realtimeTranslatedText,
                          style: const TextStyle(fontSize: 16, color: Colors.deepPurple),
                          maxLines: 4,
                          minLines: 1,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
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
