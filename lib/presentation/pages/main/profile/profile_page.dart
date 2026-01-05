import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:karrot_clone/data/models/user_model.dart';
import 'package:karrot_clone/utils/helpers/location_helper.dart';
import 'sales_history_page.dart';
import 'purchase_history_page.dart';
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
        _showEditProfileDialog();
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

  /// 프로필 수정 다이얼로그
  Future<void> _showEditProfileDialog() async {
    if (_currentUser == null) return;

    final nicknameController =
        TextEditingController(text: _currentUser!.nickname);
    final phoneController = TextEditingController(text: _currentUser!.phone);
    final locationController =
        TextEditingController(text: _currentUser!.location ?? '');

    File? selectedImage;
    String? currentImageUrl = _currentUser!.profileImageUrl;
    bool isLoadingLocation = false;

    // 현재 위치 가져오기 함수
    Future<void> fetchLocation(StateSetter setDialogState) async {
      setDialogState(() {
        isLoadingLocation = true;
      });

      try {
        // 위치 서비스 활성화 확인
        bool serviceEnabled = await LocationHelper.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('위치 서비스가 비활성화되어 있습니다.\n기기 설정에서 위치 서비스를 활성화해주세요.'),
                backgroundColor: Color(0xFFFF6626),
                duration: Duration(seconds: 3),
              ),
            );
          }
          setDialogState(() {
            isLoadingLocation = false;
          });
          return;
        }

        // 위치 권한 요청
        bool hasPermission = await LocationHelper.requestLocationPermission();
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('위치 권한이 필요합니다.'),
                backgroundColor: Color(0xFFFF6626),
                duration: Duration(seconds: 3),
              ),
            );
          }
          setDialogState(() {
            isLoadingLocation = false;
          });
          return;
        }

        // 현재 위치 가져오기
        Position? position = await LocationHelper.getCurrentPosition();
        if (position == null) {
          throw Exception('위치를 가져올 수 없습니다');
        }

        // 주소로 변환
        String address = await LocationHelper.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        setDialogState(() {
          locationController.text = address;
          isLoadingLocation = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('현재 위치를 가져왔습니다'),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        setDialogState(() {
          isLoadingLocation = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('위치를 가져올 수 없습니다: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text(
              '프로필 수정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 프로필 이미지 선택
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 512,
                        maxHeight: 512,
                        imageQuality: 80,
                      );

                      if (image != null) {
                        setDialogState(() {
                          selectedImage = File(image.path);
                        });
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: selectedImage != null
                                ? Image.file(
                                    selectedImage!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                : currentImageUrl != null
                                    ? Image.network(
                                        currentImageUrl,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Center(
                                            child: Text(
                                              '👤',
                                              style: TextStyle(fontSize: 32),
                                            ),
                                          );
                                        },
                                      )
                                    : const Center(
                                        child: Text(
                                          '👤',
                                          style: TextStyle(fontSize: 32),
                                        ),
                                      ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF700F),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 닉네임
                  TextField(
                    controller: nicknameController,
                    decoration: const InputDecoration(
                      labelText: '닉네임',
                      hintText: '닉네임을 입력하세요',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFFFF700F),
                          width: 2,
                        ),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  // 전화번호
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: '전화번호',
                      hintText: '010-0000-0000',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFFFF700F),
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  // 위치
                  TextField(
                    controller: locationController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: '위치',
                      hintText: 'GPS로 현재 위치를 가져오세요',
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFFFF700F),
                          width: 2,
                        ),
                      ),
                      suffixIcon: isLoadingLocation
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFF700F),
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.my_location,
                                color: Color(0xFFFF700F),
                              ),
                              onPressed: () => fetchLocation(setDialogState),
                              tooltip: '현재 위치 가져오기',
                            ),
                    ),
                    onTap: () => fetchLocation(setDialogState),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text(
                  '취소',
                  style: TextStyle(
                    color: Color(0xFF808080),
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  // 유효성 검사
                  if (nicknameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('닉네임을 입력해주세요'),
                        backgroundColor: Color(0xFFFF6626),
                      ),
                    );
                    return;
                  }

                  if (phoneController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('전화번호를 입력해주세요'),
                        backgroundColor: Color(0xFFFF6626),
                      ),
                    );
                    return;
                  }

                  // 로딩 다이얼로그 표시
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF700F),
                      ),
                    ),
                  );

                  try {
                    String? uploadedImageUrl = currentImageUrl;

                    // 이미지가 선택된 경우 Firebase Storage에 업로드
                    if (selectedImage != null) {
                      final storageRef = FirebaseStorage.instance
                          .ref()
                          .child('profile_images')
                          .child('${_currentUser!.id}.jpg');

                      await storageRef.putFile(selectedImage!);
                      uploadedImageUrl = await storageRef.getDownloadURL();
                    }

                    // Firestore 업데이트
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_currentUser!.id)
                        .update({
                      'nickname': nicknameController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'location': locationController.text.trim().isEmpty
                          ? null
                          : locationController.text.trim(),
                      'profileImageUrl': uploadedImageUrl,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    // 로컬 상태 업데이트
                    await _loadUserData();

                    if (mounted) {
                      // 로딩 다이얼로그 닫기
                      Navigator.pop(context);
                      // 수정 다이얼로그 닫기 (성공)
                      Navigator.pop(context, true);
                    }
                  } catch (e) {
                    if (mounted) {
                      // 로딩 다이얼로그 닫기
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('프로필 수정 실패: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  '저장',
                  style: TextStyle(
                    color: Color(0xFFFF700F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // 다이얼로그가 완전히 닫힌 후 컨트롤러 dispose
    nicknameController.dispose();
    phoneController.dispose();
    locationController.dispose();

    // 성공 시 스낵바 표시
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로필이 수정되었습니다'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PurchaseHistoryPage(),
                ),
              );
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
