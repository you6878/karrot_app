import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:karrot_clone/data/models/user_model.dart';
import 'sales_history_page.dart';
import 'favorites_page.dart';
import 'recent_viewed_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (doc.exists && mounted) {
          setState(() {
            _currentUser = UserModel.fromJson(doc.data()!);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('사용자 데이터 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '나의 당근',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF700F),
              ),
            )
          : _currentUser == null
              ? const Center(
                  child: Text(
                    '사용자 정보를 불러올 수 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF808080),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildProfileSection(),
                      const SizedBox(height: 20),
                      _buildMyTransactionsSection(),
                      const SizedBox(height: 20),
                      _buildMyInterestsSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 이미지
          _buildProfileImage(),
          const SizedBox(width: 16),
          // 사용자 정보
          Expanded(
            child: _buildUserInfo(),
          ),
          // 수정 버튼
          _buildEditButton(),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(
        child: _currentUser?.profileImageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.network(
                  _currentUser!.profileImageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text(
                      '👤',
                      style: TextStyle(fontSize: 20),
                    );
                  },
                ),
              )
            : const Text(
                '👤',
                style: TextStyle(fontSize: 20),
              ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentUser?.nickname ?? '사용자',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _currentUser?.location ?? '위치 정보 없음',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF808080),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            _showMannerTemperatureInfo();
          },
          child: Row(
            children: [
              Text(
                '매너온도 ${_currentUser?.mannerTemperature.toStringAsFixed(1) ?? '36.5'}°C',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFFF700F),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.info_outline,
                size: 14,
                color: Color(0xFFFF700F),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 매너 온도 정보 팝업
  void _showMannerTemperatureInfo() {
    final temp = _currentUser?.mannerTemperature ?? 36.5;
    String level;
    String emoji;
    Color color;

    if (temp >= 50) {
      level = '최고예요!';
      emoji = '🔥';
      color = const Color(0xFFFF6626);
    } else if (temp >= 40) {
      level = '훌륭해요!';
      emoji = '😊';
      color = const Color(0xFFFF8A00);
    } else if (temp >= 30) {
      level = '좋아요!';
      emoji = '😀';
      color = const Color(0xFFFFB800);
    } else if (temp >= 20) {
      level = '보통이에요';
      emoji = '😐';
      color = const Color(0xFF808080);
    } else {
      level = '노력이 필요해요';
      emoji = '😢';
      color = Colors.blue;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '매너온도',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              '${temp.toStringAsFixed(1)}°C',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              level,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '매너온도란?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '거래 후 상대방이 남긴 후기를 바탕으로 계산되는 신뢰도 지표입니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF808080),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• 좋아요: +2.0°C\n• 보통이에요: 변동 없음\n• 별로예요: -2.0°C',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF808080),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '확인',
              style: TextStyle(
                color: Color(0xFFFF700F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return GestureDetector(
      onTap: () {
        // TODO: 프로필 수정 페이지로 이동
        debugPrint('프로필 수정');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFF700F),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '수정',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMyTransactionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              '나의 거래',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ),
          _buildMenuItem(
            icon: '📋',
            title: '판매내역',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SalesHistoryPage(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: '🛍️',
            title: '구매내역',
            onTap: () {
              // TODO: 구매내역 페이지로 이동
              debugPrint('구매내역');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMyInterestsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              '나의 관심',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ),
          _buildMenuItem(
            icon: '❤️',
            title: '관심목록',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesPage(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: '🕒',
            title: '최근 본 상품',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecentViewedPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const Text(
              '>',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFB3B3B3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
