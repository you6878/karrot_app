import 'package:flutter/material.dart';

void main() {
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
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // 로그인 로직
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('로그인 버튼이 클릭되었습니다'),
        backgroundColor: Color(0xFFFF700F),
      ),
    );
  }

  void _handleSignUp() {
    // 회원가입 로직
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('회원가입 버튼이 클릭되었습니다'),
        backgroundColor: Color(0xFFFF700F),
      ),
    );
  }

  void _handleForgotPassword() {
    // 비밀번호 찾기 로직
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('비밀번호 찾기가 클릭되었습니다'),
        backgroundColor: Color(0xFFFF700F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: 375,
            height: 812,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // 당근 로고
                const Text(
                  '🥕',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 32),

                // 인사말
                const Text(
                  '안녕하세요!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 34),

                // 부제목
                const Text(
                  '당근마켓에 로그인하세요',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF808080),
                  ),
                ),

                const SizedBox(height: 51),

                // 입력 필드 영역
                Column(
                  children: [
                    // 이메일 입력 필드
                    Container(
                      width: 307,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        border: Border.all(
                          color: const Color(0xFFE6E6E6),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          hintText: '이메일을 입력하세요',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFB3B3B3),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 패스워드 입력 필드
                    Container(
                      width: 307,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        border: Border.all(
                          color: const Color(0xFFE6E6E6),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: '비밀번호를 입력하세요',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFB3B3B3),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 버튼 영역
                Column(
                  children: [
                    // 로그인 버튼
                    GestureDetector(
                      onTap: _handleLogin,
                      child: Container(
                        width: 307,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF700F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            '로그인',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 회원가입 버튼
                    GestureDetector(
                      onTap: _handleSignUp,
                      child: Container(
                        width: 307,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFFFF700F),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            '회원가입',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF700F),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 42),

                // 비밀번호 찾기 링크
                GestureDetector(
                  onTap: _handleForgotPassword,
                  child: const Text(
                    '비밀번호를 잊으셨나요?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFFF700F),
                    ),
                  ),
                ),

                const SizedBox(height: 49),

                // 약관 동의
                const Text(
                  '이용약관 및 개인정보처리방침에 동의합니다',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
