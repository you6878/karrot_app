import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'presentation/pages/auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const KarrotCloneApp());
}

class KarrotCloneApp extends StatelessWidget {
  const KarrotCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '당근마켓',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColor: const Color(0xFFFF700F),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
