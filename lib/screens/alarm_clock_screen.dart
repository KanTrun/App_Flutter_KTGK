import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';

class AlarmClockScreen extends StatefulWidget {
  const AlarmClockScreen({super.key});

  @override
  State<AlarmClockScreen> createState() => _AlarmClockScreenState();
}

class _AlarmClockScreenState extends State<AlarmClockScreen> {
  TimeOfDay? _selectedTime;
  String _alarmLabel = '';
  bool _isAlarmSet = false;
  Timer? _alarmTimer;
  DateTime? _alarmDateTime;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _labelController = TextEditingController();
  
  // Voice recognition variables
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _speechListening = false;
  String _lastWords = '';
  String _lastAction = '';
  
  // List of alarm sounds (we'll use system sounds for demo)
  final List<String> _alarmSounds = [
    'Chuông báo thức cơ bản',
    'Tiếng chim hót',
    'Âm thanh nhẹ nhàng',
    'Chuông điện thoại',
  ];
  String _selectedSound = 'Chuông báo thức cơ bản';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      await Permission.microphone.request();
      _speechEnabled = await _speechToText.initialize();
      setState(() {});
    } catch (e) {
      print('Error initializing speech: $e');
      _speechEnabled = false;
    }
  }

  @override
  void dispose() {
    _alarmTimer?.cancel();
    _audioPlayer.dispose();
    _labelController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  // Speech recognition methods - Voice control thực sự
  void _startListening() async {
    if (_speechEnabled) {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        localeId: 'vi_VN',
      );
      setState(() {
        _speechListening = true;
        _lastAction = 'Đang nghe giọng nói...';
      });
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _speechListening = false;
    });
  }

  void _onSpeechResult(result) {
    setState(() {
      _lastWords = result.recognizedWords.toLowerCase();
    });
    if (result.finalResult) {
      _processVoiceCommand(_lastWords);
      _stopListening();
    }
  }

  void _processVoiceCommand(String command) {
    String originalCommand = _lastWords.toLowerCase();
    command = command.toLowerCase().replaceAll(' ', '');
    
    setState(() {
      _lastAction = 'Đã nghe: "$_lastWords"';
    });

    // Voice commands để đặt báo thức
    if (command.contains('đặtbáothức') || command.contains('đặtgiờ') || command.contains('báothức') || 
        originalCommand.contains('báo thức') || originalCommand.contains('đặt giờ')) {
      
      TimeOfDay? parsedTime = _parseTimeFromVietnamese(originalCommand);
      
      if (parsedTime != null) {
        setState(() {
          _selectedTime = parsedTime;
          _lastAction = 'Đã đặt báo thức bằng giọng nói: ${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')}';
        });
        _setAlarm();
      } else {
        setState(() {
          _lastAction = 'Không hiểu thời gian. Hãy nói như: "đặt báo thức 7 giờ 30 phút", "báo thức 6 giờ sáng", "đặt giờ 8 rưỡi"';
        });
      }
    }
    // Hủy báo thức
    else if (command.contains('hủybáothức') || command.contains('tắtbáothức') || command.contains('hủy')) {
      if (_isAlarmSet) {
        _cancelAlarm();
        setState(() {
          _lastAction = 'Đã hủy báo thức bằng giọng nói';
        });
      } else {
        setState(() {
          _lastAction = 'Không có báo thức nào để hủy';
        });
      }
    }
    // Tắt âm thanh báo thức
    else if (command.contains('tắt') || command.contains('dừng')) {
      _stopAlarmSound();
      setState(() {
        _lastAction = 'Đã tắt âm thanh báo thức';
      });
    }
    else {
      setState(() {
        _lastAction = 'Không hiểu lệnh. Thử nói "đặt báo thức [giờ] [phút]" hoặc "hủy báo thức"';
      });
    }
  }

  // Giữ lại quick buttons làm backup
  void _quickSetAlarm(int hour, int minute) {
    setState(() {
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
      _lastAction = 'Đã chọn ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    });
    _setAlarm();
  }

  void _quickCancelAlarm() {
    if (_isAlarmSet) {
      _cancelAlarm();
      setState(() {
        _lastAction = 'Đã hủy báo thức';
      });
    }
  }

  Widget _buildQuickTimeButton(String timeText, int hour, int minute) {
    return ElevatedButton(
      onPressed: _isAlarmSet ? null : () => _quickSetAlarm(hour, minute),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isAlarmSet ? Colors.grey.shade400 : Colors.purple.shade600,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        timeText,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Thông minh parse thời gian tiếng Việt
  TimeOfDay? _parseTimeFromVietnamese(String input) {
    input = input.toLowerCase().trim();
    
    // Map số tiếng Việt sang số
    Map<String, String> vietnameseNumbers = {
      'một': '1', 'hai': '2', 'ba': '3', 'bốn': '4', 'năm': '5',
      'sáu': '6', 'bảy': '7', 'tám': '8', 'chín': '9', 'mười': '10',
      'mười một': '11', 'mười hai': '12', 'mười ba': '13', 'mười bốn': '14', 
      'mười lăm': '15', 'mười sáu': '16', 'mười bảy': '17', 'mười tám': '18',
      'mười chín': '19', 'hai mười': '20', 'hai mườ một': '21', 'hai mười hai': '22',
      'hai mười ba': '23'
    };
    
    // Thay thế số tiếng Việt
    vietnameseNumbers.forEach((key, value) {
      input = input.replaceAll(key, value);
    });
    
    // Các pattern nhận diện thời gian
    List<RegExp> patterns = [
      // "7 giờ 30 phút", "bảy giờ ba mười phút" 
      RegExp(r'(\d{1,2})\s*giờ\s*(\d{1,2})\s*phút'),
      // "7:30", "07:30"
      RegExp(r'(\d{1,2})\s*:\s*(\d{1,2})'),
      // "7 giờ rưỡi", "bảy giờ rưỡi"
      RegExp(r'(\d{1,2})\s*giờ\s*rưỡi'),
      // "7 giờ", "bảy giờ" 
      RegExp(r'(\d{1,2})\s*giờ(?!\s*rưỡi)'),
      // "7h30", "7h 30"
      RegExp(r'(\d{1,2})\s*h\s*(\d{1,2})'),
      // "7h30p", "7h30phút"
      RegExp(r'(\d{1,2})\s*h\s*(\d{1,2})\s*p'),
    ];
    
    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(input);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = 0;
        
        // Xử lý phút nếu có
        if (match.group(2) != null) {
          minute = int.parse(match.group(2)!);
        } else if (input.contains('rưỡi')) {
          minute = 30;
        }
        
        // Xử lý AM/PM
        if (input.contains('sáng') && hour <= 12 && hour != 12) {
          // Giữ nguyên giờ sáng
        } else if (input.contains('chiều') || input.contains('tối')) {
          if (hour < 12) hour += 12;
        } else if (input.contains('trưa') && hour == 12) {
          // 12 giờ trưa = 12:00
        }
        
        // Validate thời gian
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    }
    
    return null;
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  String _getCurrentTime() {
    return DateFormat('HH:mm:ss').format(DateTime.now());
  }

  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _openSystemAlarm() async {
    try {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.SET_ALARM',
        arguments: {
          'android.intent.extra.alarm.HOUR': _selectedTime!.hour,
          'android.intent.extra.alarm.MINUTES': _selectedTime!.minute,
          'android.intent.extra.alarm.MESSAGE': _labelController.text.isNotEmpty 
              ? _labelController.text 
              : 'Báo thức từ ứng dụng',
          'android.intent.extra.alarm.SKIP_UI': false,
        },
      );
      await intent.launch();
      _showMessage('Đã mở ứng dụng báo thức hệ thống!');
    } catch (e) {
      _showMessage('Không thể mở ứng dụng báo thức: $e');
    }
  }

  void _setAlarm() {
    if (_selectedTime == null) {
      _showMessage('Vui lòng chọn thời gian báo thức');
      return;
    }

    final now = DateTime.now();
    DateTime alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // If alarm time is before current time, set for next day
    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

    final duration = alarmTime.difference(now);

    setState(() {
      _isAlarmSet = true;
      _alarmDateTime = alarmTime;
      _alarmLabel = _labelController.text.isNotEmpty 
          ? _labelController.text 
          : 'Báo thức ${_formatTime(_selectedTime!)}';
    });

    _alarmTimer = Timer(duration, () {
      _triggerAlarm();
    });

    _showMessage('Báo thức đã được đặt cho ${DateFormat('HH:mm dd/MM/yyyy').format(alarmTime)}');
  }

  void _cancelAlarm() {
    setState(() {
      _isAlarmSet = false;
      _alarmDateTime = null;
      _alarmTimer?.cancel();
      _alarmTimer = null;
    });
    _showMessage('Đã hủy báo thức');
  }

  void _triggerAlarm() {
    _playAlarmSound();
    _showAlarmDialog();
  }

  void _playAlarmSound() async {
    try {
      // Sử dụng file audio1.mp3 trong assets
      await _audioPlayer.play(AssetSource('audio/audio1.mp3'));
    } catch (e) {
      // Nếu không phát được âm thanh, chỉ hiện dialog
      print('Could not play alarm sound: $e');
    }
  }

  void _stopAlarmSound() {
    _audioPlayer.stop();
  }

  void _showAlarmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.alarm, color: Colors.red.shade600, size: 30),
              const SizedBox(width: 10),
              const Text('⏰ BÁO THỨC!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _alarmLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Thời gian: ${_getCurrentTime()}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              // Animated alarm icon
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: 1 + (value * 0.2),
                    child: Icon(
                      Icons.alarm,
                      size: 60,
                      color: Colors.red.shade600,
                    ),
                  );
                },
                onEnd: () {
                  // Repeat animation
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _stopAlarmSound();
                Navigator.of(context).pop();
                setState(() {
                  _isAlarmSet = false;
                  _alarmDateTime = null;
                });
              },
              child: const Text(
                'TẮT BÁO THỨC',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getTimeUntilAlarm() {
    if (!_isAlarmSet || _alarmDateTime == null) return '';
    
    final now = DateTime.now();
    final difference = _alarmDateTime!.difference(now);
    
    if (difference.isNegative) return '';
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    
    if (hours > 0) {
      return 'Còn $hours giờ $minutes phút';
    } else {
      return 'Còn $minutes phút';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đồng hồ báo thức'),
        centerTitle: true,
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.shade50,
              Colors.amber.shade50,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Current time display
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: Colors.orange.shade600,
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      children: [
                        const Text(
                          'Thời gian hiện tại',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder(
                          stream: Stream.periodic(const Duration(seconds: 1)),
                          builder: (context, snapshot) {
                            return Text(
                              _getCurrentTime(),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Alarm settings card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cài đặt báo thức',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Time picker
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Thời gian báo thức:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _selectedTime != null 
                                          ? _formatTime(_selectedTime!)
                                          : 'Chọn thời gian...',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedTime != null 
                                            ? Colors.orange.shade700
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            ElevatedButton.icon(
                              onPressed: _selectTime,
                              icon: const Icon(Icons.access_time, size: 20),
                              label: const Text('Chọn'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Alarm label
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ghi chú báo thức:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _labelController,
                              decoration: InputDecoration(
                                hintText: 'Nhập ghi chú (tùy chọn)...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.all(15),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Sound selection
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Âm thanh báo thức:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedSound,
                                isExpanded: true,
                                underline: Container(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedSound = newValue!;
                                  });
                                },
                                items: _alarmSounds.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 25),
                        
                        // Set/Cancel alarm buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isAlarmSet ? null : _setAlarm,
                                icon: const Icon(Icons.alarm_add, size: 24),
                                label: const Text(
                                  'Đặt báo thức',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isAlarmSet 
                                      ? Colors.grey.shade400
                                      : Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isAlarmSet ? _cancelAlarm : null,
                                icon: const Icon(Icons.alarm_off, size: 24),
                                label: const Text(
                                  'Hủy báo thức',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isAlarmSet 
                                      ? Colors.red.shade600
                                      : Colors.grey.shade400,
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // System alarm button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _selectedTime != null ? _openSystemAlarm : null,
                            icon: const Icon(Icons.smartphone, size: 24),
                            label: const Text(
                              'Đặt báo thức hệ thống',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedTime != null 
                                  ? Colors.orange.shade600
                                  : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Voice Control - Điều khiển giọng nói thực sự
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.mic, color: Colors.blue.shade600, size: 24),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Điều khiển giọng nói',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              
                              // Voice control button
                              ElevatedButton.icon(
                                onPressed: _speechEnabled 
                                    ? (_speechListening ? _stopListening : _startListening) 
                                    : null,
                                icon: Icon(
                                  _speechListening ? Icons.mic : Icons.mic_none,
                                  size: 24,
                                ),
                                label: Text(
                                  _speechListening 
                                      ? 'Đang nghe... (nhấn để dừng)' 
                                      : (_speechEnabled ? 'Bấm và nói' : 'Microphone không khả dụng'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _speechListening 
                                      ? Colors.red.shade600
                                      : (_speechEnabled ? Colors.blue.shade600 : Colors.grey.shade400),
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 15),
                              
                              // Hướng dẫn sử dụng
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Hướng dẫn:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '• "Đặt báo thức 7 giờ 30 phút"\n• "Báo thức 8 giờ rưỡi sáng"\n• "Đặt giờ 6:45"\n• "Báo thức hai mười hai giờ"\n• "Hủy báo thức" / "Tắt báo thức"',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ],
                                ),
                              ),
                              
                              if (_lastAction.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Text(
                                    _lastAction,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                              
                              const SizedBox(height: 15),
                              
                              // Backup quick buttons
                              ExpansionTile(
                                title: const Text(
                                  'Hoặc chọn nhanh',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildQuickTimeButton('6:00', 6, 0),
                                      _buildQuickTimeButton('6:30', 6, 30),
                                      _buildQuickTimeButton('7:00', 7, 0),
                                      _buildQuickTimeButton('7:30', 7, 30),
                                      _buildQuickTimeButton('8:00', 8, 0),
                                      _buildQuickTimeButton('9:00', 9, 0),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: _isAlarmSet ? _quickCancelAlarm : null,
                                    icon: const Icon(Icons.clear, size: 16),
                                    label: const Text('Hủy nhanh'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isAlarmSet 
                                          ? Colors.red.shade600
                                          : Colors.grey.shade400,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Active alarm display
                if (_isAlarmSet) ...[
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.alarm_on, color: Colors.green.shade600, size: 30),
                              const SizedBox(width: 10),
                              const Text(
                                'Báo thức đang hoạt động',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _alarmLabel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _alarmDateTime != null 
                                      ? 'Báo thức lúc: ${DateFormat('HH:mm dd/MM/yyyy').format(_alarmDateTime!)}'
                                      : '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                StreamBuilder(
                                  stream: Stream.periodic(const Duration(seconds: 1)),
                                  builder: (context, snapshot) {
                                    return Text(
                                      _getTimeUntilAlarm(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade700,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}