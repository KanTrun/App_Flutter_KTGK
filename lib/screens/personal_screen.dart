import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';

class PersonalScreen extends StatelessWidget {
  const PersonalScreen({super.key});

  Future<void> _openDialer() async {
    try {
      // Mở ứng dụng Điện thoại của Android
      final AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.DIAL',
      );
      await intent.launch();
    } catch (e) {
      print('Không thể mở ứng dụng điện thoại: $e');
    }
  }

  Future<void> _openYouTube() async {
    try {
      // Thử mở ứng dụng YouTube trước
      final Uri youtubeApp = Uri.parse('youtube://');
      if (await canLaunchUrl(youtubeApp)) {
        await launchUrl(youtubeApp);
      } else {
        // Nếu không có app thì mở web
        final Uri youtubeWeb = Uri.parse('https://www.youtube.com');
        await launchUrl(youtubeWeb, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Không thể mở YouTube: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang cá nhân'),
        centerTitle: true,
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade50,
              Colors.pink.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              // Welcome section
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.purple.shade50,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.purple.shade600,
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Chào mừng bạn!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Truy cập nhanh các ứng dụng',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Phone Dialer Button
              SizedBox(
                width: double.infinity,
                height: 70,
                child: ElevatedButton.icon(
                  onPressed: _openDialer,
                  icon: const Icon(
                    Icons.phone,
                    size: 30,
                  ),
                  label: const Text(
                    'Mở ứng dụng Điện thoại',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    shadowColor: Colors.green.shade200,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // YouTube Button
              SizedBox(
                width: double.infinity,
                height: 70,
                child: ElevatedButton.icon(
                  onPressed: _openYouTube,
                  icon: const Icon(
                    Icons.play_circle_filled,
                    size: 30,
                  ),
                  label: const Text(
                    'Mở ứng dụng YouTube',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    shadowColor: Colors.red.shade200,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Info card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 40,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Thông tin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Nút "Điện thoại" sẽ mở ứng dụng quay số\n'
                        '• Nút "YouTube" sẽ mở ứng dụng YouTube\n'
                        '• Các ứng dụng sẽ mở bên ngoài app này',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}