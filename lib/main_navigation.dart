import 'package:flutter/material.dart';
import 'screens/personal_screen.dart';
import 'screens/youtube_player_screen.dart';
import 'screens/alarm_clock_screen.dart';
import 'screens/translation_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const PersonalScreen(),
    const YouTubePlayerScreen(),
    const AlarmClockScreen(),
    const TranslationScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Cá nhân',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.play_circle_filled),
      label: 'YouTube',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.alarm),
      label: 'Báo thức',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.translate),
      label: 'Dịch văn bản',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue.shade600,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 11,
        ),
        items: _navItems,
      ),
    );
  }
}