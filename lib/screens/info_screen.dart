import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  final List<Map<String, String>> people = [
    {
      'name': 'Trương Minh Khang',
      'school': 'trường HUTECH',
      'gender': 'Nam',
      'hobby': 'Lập trình, Đọc sách, Du lịch',
      'image': 'assets/images/image1.png',
    },
    {
      'name': 'Hà Nguyễn Hồng Phúc',
      'school': 'trường HUTECH',
      'gender': 'Nam',
      'hobby': 'Âm nhạc, Chơi game, Thể thao',
      'image': 'assets/images/image2.png',
    },
    {
      'name': 'Phạm Thành Nghị',
      'school': 'trường HUTECH',
      'gender': 'Nam',
      'hobby': 'Bóng đá, Xem phim, Nấu ăn',
      'image': 'assets/images/image3.png',
    },
    {
      'name': 'Nguyễn Hoàng Yến',
      'school': 'trường HUTECH',
      'gender': 'Nữ',
      'hobby': 'Vẽ, Du lịch, Đọc truyện',
      'image': 'assets/images/image4.png',
    },
  ];

  InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin nhóm'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: PageView.builder(
        itemCount: people.length,
        itemBuilder: (context, index) {
          final person = people[index];
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundImage: AssetImage(person['image']!),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    person['name']!,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    person['school']!,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text('Giới tính: ${person['gender']}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite, color: Colors.pink),
                      const SizedBox(width: 8),
                      Text('Sở thích: ${person['hobby']}'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
