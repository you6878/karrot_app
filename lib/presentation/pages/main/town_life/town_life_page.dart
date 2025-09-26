import 'package:flutter/material.dart';

class TownLifePage extends StatefulWidget {
  const TownLifePage({super.key});

  @override
  State<TownLifePage> createState() => _TownLifePageState();
}

class _TownLifePageState extends State<TownLifePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '동네생활',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
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
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '📍',
              style: TextStyle(fontSize: 48),
            ),
            SizedBox(height: 16),
            Text(
              '동네생활',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '동네 소식과 정보가 여기에 표시됩니다',
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
