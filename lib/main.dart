import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/main/main_navigation_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF700F),
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            return const MainNavigationPage();
          } else {
            return const LoginPage();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
