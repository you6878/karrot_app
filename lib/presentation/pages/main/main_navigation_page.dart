import 'package:flutter/material.dart';
import 'home/home_page.dart';
import 'town_life/town_life_page.dart';
import 'chat/chat_list_page.dart';
import 'profile/profile_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const TownLifePage(),
    const ChatListPage(),
    const ProfilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Color(0xFFE6E6E6),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          selectedItemColor: const Color(0xFFFF700F),
          unselectedItemColor: const Color(0xFF808080),
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontFamily: 'Inter',
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '🏠',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '🏠',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '📍',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '📍',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              label: '동네생활',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '💬',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '💬',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              label: '채팅',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '👤',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '👤',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              label: '나의 당근',
            ),
          ],
        ),
      ),
    );
  }
}
