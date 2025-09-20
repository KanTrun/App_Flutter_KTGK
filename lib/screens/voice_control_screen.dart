import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class VoiceControlScreen extends StatefulWidget {
  const VoiceControlScreen({Key? key}) : super(key: key);

  @override
  State<VoiceControlScreen> createState() => _VoiceControlScreenState();
}

class _VoiceControlScreenState extends State<VoiceControlScreen> 
    with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Nhấn micro để bắt đầu...';
  String _lastWords = '';
  
  // Timer functionality
  Timer? _timer;
  int _seconds = 0;
  bool _isTimerRunning = false;
  
  // Stopwatch functionality  
  Stopwatch _stopwatch = Stopwatch();
  bool _isStopwatchRunning = false;
  
  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeSpeech();
    
    // Initialize animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );
    
    if (!available) {
      setState(() {
        _text = 'Không thể khởi tạo nhận diện giọng nói';
      });
    }
  }

  void _listen() async {
    // Check microphone permission
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        setState(() {
          _text = 'Cần cấp quyền microphone để sử dụng tính năng này';
        });
        return;
      }
    }

    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            _lastWords = val.recognizedWords.toLowerCase();
            _processVoiceCommand(_lastWords);
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _processVoiceCommand(String command) {
    print('Processing command: $command');
    
    // Timer commands
    if (command.contains('đặt giờ') || command.contains('báo thức')) {
      _processTimerCommand(command);
    }
    // Stopwatch commands
    else if (command.contains('bấm giờ') || command.contains('đồng hồ bấm giờ')) {
      _processStopwatchCommand(command);
    }
    // Stop commands
    else if (command.contains('dừng') || command.contains('ngừng')) {
      _stopAllTimers();
    }
    // Reset commands
    else if (command.contains('đặt lại') || command.contains('reset')) {
      _resetAll();
    }
  }

  void _processTimerCommand(String command) {
    // Extract numbers from command
    RegExp regExp = RegExp(r'\d+');
    Iterable<Match> matches = regExp.allMatches(command);
    
    if (matches.isNotEmpty) {
      int minutes = int.parse(matches.first.group(0)!);
      _startTimer(minutes);
      
      setState(() {
        _text = 'Đã đặt báo thức $minutes phút';
      });
    } else {
      setState(() {
        _text = 'Không thể nhận diện thời gian. Hãy nói "đặt giờ 5 phút"';
      });
    }
  }

  void _processStopwatchCommand(String command) {
    if (command.contains('bắt đầu') || command.contains('khởi động')) {
      _startStopwatch();
    } else if (command.contains('dừng') || command.contains('tạm dừng')) {
      _pauseStopwatch();
    } else {
      _startStopwatch(); // Default action
    }
  }

  void _startTimer(int minutes) {
    _timer?.cancel();
    _seconds = minutes * 60;
    _isTimerRunning = true;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          _timer?.cancel();
          _isTimerRunning = false;
          _playAlarmSound();
          _showAlarmDialog();
        }
      });
    });
  }

  void _startStopwatch() {
    if (!_isStopwatchRunning) {
      _stopwatch.start();
      _isStopwatchRunning = true;
      
      setState(() {
        _text = 'Đồng hồ bấm giờ đã bắt đầu';
      });
      
      // Update stopwatch display every 10ms
      Timer.periodic(const Duration(milliseconds: 10), (timer) {
        if (!_isStopwatchRunning) {
          timer.cancel();
          return;
        }
        setState(() {});
      });
    }
  }

  void _pauseStopwatch() {
    if (_isStopwatchRunning) {
      _stopwatch.stop();
      _isStopwatchRunning = false;
      setState(() {
        _text = 'Đồng hồ bấm giờ đã tạm dừng';
      });
    }
  }

  void _stopAllTimers() {
    _timer?.cancel();
    _isTimerRunning = false;
    
    if (_isStopwatchRunning) {
      _stopwatch.stop();
      _isStopwatchRunning = false;
    }
    
    setState(() {
      _text = 'Đã dừng tất cả đồng hồ';
    });
  }

  void _resetAll() {
    _timer?.cancel();
    _isTimerRunning = false;
    _seconds = 0;
    
    _stopwatch.reset();
    _isStopwatchRunning = false;
    
    setState(() {
      _text = 'Đã đặt lại tất cả';
    });
  }

  void _playAlarmSound() async {
    try {
      await _audioPlayer.play(AssetSource('audio/audio1.mp3'));
    } catch (e) {
      print('Could not play alarm sound: $e');
    }
  }

  void _showAlarmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⏰ Báo thức'),
        content: const Text('Hết giờ!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _audioPlayer.stop();
            },
            child: const Text('Tắt'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatStopwatch() {
    int milliseconds = _stopwatch.elapsedMilliseconds;
    int minutes = (milliseconds ~/ 60000);
    int seconds = ((milliseconds % 60000) ~/ 1000);
    int hundredths = ((milliseconds % 1000) ~/ 10);
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundredths.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Điều khiển giọng nói',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple.shade600,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Voice recognition card
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade400,
                      Colors.deepPurple.shade600,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    // Microphone button
                    GestureDetector(
                      onTap: _listen,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isListening ? _pulseAnimation.value : 1.0,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isListening 
                                    ? Colors.red.shade400
                                    : Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                size: 50,
                                color: _isListening 
                                    ? Colors.white
                                    : Colors.deepPurple.shade600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Status text
                    Text(
                      _isListening ? 'Đang nghe...' : 'Nhấn để nói',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Recognized text
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lệnh đã nhận:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _text,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Timer display
            if (_isTimerRunning) ...[
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade300, Colors.orange.shade500],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '⏲️ Báo thức',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _formatTime(_seconds),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],
            
            // Stopwatch display
            if (_isStopwatchRunning || _stopwatch.elapsedMilliseconds > 0) ...[
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade300, Colors.blue.shade500],
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _isStopwatchRunning ? '⏱️ Đang chạy' : '⏱️ Tạm dừng',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _formatStopwatch(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],
            
            // Instructions
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Hướng dẫn sử dụng',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildInstructionItem('🎯 "Đặt giờ 5 phút" - Đặt báo thức'),
                    _buildInstructionItem('⏱️ "Bấm giờ bắt đầu" - Khởi động stopwatch'),
                    _buildInstructionItem('⏸️ "Dừng" - Dừng tất cả đồng hồ'),
                    _buildInstructionItem('🔄 "Đặt lại" - Reset tất cả'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.4,
        ),
      ),
    );
  }
}