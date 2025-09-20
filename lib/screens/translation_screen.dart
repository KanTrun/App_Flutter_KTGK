import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Text Translation
  final TextEditingController _textController = TextEditingController();
  final GoogleTranslator _translator = GoogleTranslator();
  String _translatedText = '';
  bool _isVietnameseToEnglish = true;
  bool _isTranslating = false;
  
  // Voice Recognition
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _speechListening = false;
  String _voiceText = '';
  String _voiceTranslatedText = '';
  bool _isVietnameseVoice = true;
  
  // Image OCR
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  File? _selectedImage;
  String _extractedText = '';
  String _imageTranslatedText = '';
  bool _isProcessingImage = false;
  bool _isVietnameseImage = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initSpeech();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  Future<void> _translateText(String text, bool viToEn, Function(String) onResult) async {
    if (text.trim().isEmpty) return;
    
    try {
      String fromLang = viToEn ? 'vi' : 'en';
      String toLang = viToEn ? 'en' : 'vi';
      
      Translation translation = await _translator.translate(text, from: fromLang, to: toLang);
      onResult(translation.text);
    } catch (e) {
      onResult('Lỗi dịch: $e');
    }
  }

  void _startListening() async {
    if (!_speechEnabled) return;
    
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;
    
    setState(() {
      _speechListening = true;
      _voiceText = '';
      _voiceTranslatedText = '';
    });
    
    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _voiceText = result.recognizedWords;
        });
        
        if (result.finalResult) {
          _translateVoiceText();
        }
      },
      localeId: _isVietnameseVoice ? 'vi_VN' : 'en_US',
    );
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _speechListening = false;
    });
  }

  void _translateVoiceText() async {
    if (_voiceText.isNotEmpty) {
      await _translateText(_voiceText, _isVietnameseVoice, (result) {
        setState(() {
          _voiceTranslatedText = result;
        });
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _extractedText = '';
          _imageTranslatedText = '';
          _isProcessingImage = true;
        });
        
        await _extractTextFromImage(File(image.path));
      }
    } catch (e) {
      setState(() {
        _isProcessingImage = false;
      });
      _showSnackBar('Lỗi khi chọn ảnh: $e');
    }
  }

  Future<void> _extractTextFromImage(File image) async {
    try {
      final InputImage inputImage = InputImage.fromFile(image);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      String extractedText = recognizedText.text;
      
      setState(() {
        _extractedText = extractedText;
        _isProcessingImage = false;
      });
      
      if (extractedText.isNotEmpty) {
        await _translateText(extractedText, _isVietnameseImage, (result) {
          setState(() {
            _imageTranslatedText = result;
          });
        });
      }
    } catch (e) {
      setState(() {
        _isProcessingImage = false;
      });
      _showSnackBar('Lỗi khi nhận dạng văn bản: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dịch văn bản'),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.text_fields), text: 'Văn bản'),
            Tab(icon: Icon(Icons.mic), text: 'Giọng nói'),
            Tab(icon: Icon(Icons.camera_alt), text: 'Ảnh chụp'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade50,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTextTranslationTab(),
            _buildVoiceTranslationTab(),
            _buildImageTranslationTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextTranslationTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Language toggle
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_isVietnameseToEnglish ? 'Việt Nam' : 'English'),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isVietnameseToEnglish = !_isVietnameseToEnglish;
                        _translatedText = '';
                      });
                    },
                    icon: const Icon(Icons.swap_horiz),
                  ),
                  Text(_isVietnameseToEnglish ? 'English' : 'Việt Nam'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Input text field
          Expanded(
            flex: 2,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhập văn bản (${_isVietnameseToEnglish ? 'Tiếng Việt' : 'English'}):',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Gõ văn bản cần dịch...',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Translate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isTranslating ? null : () async {
                setState(() {
                  _isTranslating = true;
                });
                
                await _translateText(_textController.text, _isVietnameseToEnglish, (result) {
                  setState(() {
                    _translatedText = result;
                    _isTranslating = false;
                  });
                });
              },
              icon: _isTranslating ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ) : const Icon(Icons.translate),
              label: Text(_isTranslating ? 'Đang dịch...' : 'Dịch văn bản'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Translation result
          Expanded(
            flex: 2,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kết quả dịch (${_isVietnameseToEnglish ? 'English' : 'Tiếng Việt'}):',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _translatedText.isEmpty ? 'Kết quả dịch sẽ hiển thị ở đây...' : _translatedText,
                            style: TextStyle(
                              fontSize: 16,
                              color: _translatedText.isEmpty ? Colors.grey : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceTranslationTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Language toggle for voice
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_isVietnameseVoice ? 'Việt Nam' : 'English'),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isVietnameseVoice = !_isVietnameseVoice;
                        _voiceText = '';
                        _voiceTranslatedText = '';
                      });
                    },
                    icon: const Icon(Icons.swap_horiz),
                  ),
                  Text(_isVietnameseVoice ? 'English' : 'Việt Nam'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Voice input section
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Microphone button
                GestureDetector(
                  onTap: _speechListening ? _stopListening : _startListening,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _speechListening ? Colors.red.shade600 : Colors.indigo.shade600,
                      boxShadow: [
                        BoxShadow(
                          color: (_speechListening ? Colors.red : Colors.indigo).shade200,
                          spreadRadius: _speechListening ? 10 : 5,
                          blurRadius: 15,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      _speechListening ? Icons.mic : Icons.mic_none,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  _speechListening ? 'Đang nghe...' : 'Chạm để bắt đầu nói',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _speechListening ? Colors.red.shade600 : Colors.indigo.shade600,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Voice text result
                if (_voiceText.isNotEmpty) ...[
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Văn bản nhận dạng (${_isVietnameseVoice ? 'Tiếng Việt' : 'English'}):',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(_voiceText, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (_voiceTranslatedText.isNotEmpty)
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kết quả dịch (${_isVietnameseVoice ? 'English' : 'Tiếng Việt'}):',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(_voiceTranslatedText, style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageTranslationTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Language toggle for image
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_isVietnameseImage ? 'Việt Nam' : 'English'),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isVietnameseImage = !_isVietnameseImage;
                        _extractedText = '';
                        _imageTranslatedText = '';
                      });
                    },
                    icon: const Icon(Icons.swap_horiz),
                  ),
                  Text(_isVietnameseImage ? 'English' : 'Việt Nam'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Camera buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Chụp ảnh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Chọn ảnh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Image display and results
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_selectedImage != null) ...[
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ảnh đã chọn:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImage!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                  
                  if (_isProcessingImage)
                    const Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 16),
                            Text('Đang nhận dạng văn bản...'),
                          ],
                        ),
                      ),
                    ),
                  
                  if (_extractedText.isNotEmpty) ...[
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Văn bản nhận dạng (${_isVietnameseImage ? 'Tiếng Việt' : 'English'}):',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(_extractedText, style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                  
                  if (_imageTranslatedText.isNotEmpty)
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kết quả dịch (${_isVietnameseImage ? 'English' : 'Tiếng Việt'}):',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(_imageTranslatedText, style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}