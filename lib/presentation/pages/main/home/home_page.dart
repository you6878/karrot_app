import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(
              Icons.location_on,
              color: Color(0xFFFF700F),
              size: 20,
            ),
            SizedBox(width: 4),
            Text(
              '역삼동',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF333333),
              size: 20,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.search,
              color: Color(0xFF333333),
              size: 24,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF333333),
              size: 24,
            ),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🏠',
              style: TextStyle(fontSize: 48),
            ),
            SizedBox(height: 16),
            Text(
              '홈 페이지',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '상품 목록이 여기에 표시됩니다',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF808080),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
