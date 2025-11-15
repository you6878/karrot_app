import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'firebase_options.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/main/main_navigation_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 네이버 지도 초기화
  await _initializeNaverMap();

  runApp(const KarrotCloneApp());
}

/// 네이버 지도 초기화
Future<void> _initializeNaverMap() async {
  await FlutterNaverMap().init(
    clientId: '5xjycgt7vt', // TODO: 네이버 클라우드 플랫폼에서 발급받은 Client ID로 변경
    onAuthFailed: (ex) {
      switch (ex) {
        case NQuotaExceededException(:final message):
          debugPrint("네이버 지도 사용량 초과 (message: $message)");
          break;
        case NUnauthorizedClientException() ||
              NClientUnspecifiedException() ||
              NAnotherAuthFailedException():
          debugPrint("네이버 지도 인증 실패: $ex");
          break;
      }
    },
  );
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
