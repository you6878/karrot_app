import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:karrot_clone/domain/entities/product.dart';
import 'package:karrot_clone/presentation/pages/chat/chat_room_page.dart';
import 'package:karrot_clone/domain/usecases/create_chat_usecase.dart';
import 'package:karrot_clone/data/repositories/chat_repository_impl.dart';
import 'package:karrot_clone/data/repositories/user_repository_impl.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  late final CreateChatUseCase _createChatUseCase;

  bool isFavorite = false;
  int currentImageIndex = 0;
  int likeCount = 0;

  @override
  void initState() {
    super.initState();
    _createChatUseCase = CreateChatUseCase(
      chatRepository: ChatRepositoryImpl(),
      userRepository: UserRepositoryImpl(),
    );
    _initializeLikeStatus();
  }

  /// 초기 좋아요 상태 확인
  void _initializeLikeStatus() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        isFavorite = widget.product.likeUids.contains(currentUser.uid);
        likeCount = widget.product.likeCount;
      });
    } else {
      setState(() {
        likeCount = widget.product.likeCount;
      });
    }
  }

  /// 채팅방 생성 또는 가져오기 (participants 정보 포함)
  Future<void> _createOrGetChatRoom(String myUid) async {
    final sellerId = widget.product.sellerId;

    try {
      // CreateChatUseCase를 사용하여 채팅방 생성 (유저 정보 자동 포함)
      final chatEntity = await _createChatUseCase(
        productId: widget.product.id,
        buyerId: myUid,
        sellerId: sellerId,
      );

      // 판매자 정보 가져오기 (participants에서)
      final sellerInfo = chatEntity.participants[sellerId];
      final sellerName = sellerInfo?.name ?? '판매자';

      // 채팅방으로 이동
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomPage(
              product: widget.product,
              partnerId: sellerId,
              partnerName: sellerName,
            ),
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 좋아요 토글
  Future<void> _toggleLike() async {
    final currentUser = _auth.currentUser;

    // 로그인하지 않은 경우
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인이 필요한 기능입니다'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFFFF6626),
          ),
        );
      }
      return;
    }

    final uid = currentUser.uid;
    final productRef = _firestore.collection('products').doc(widget.product.id);

    try {
      // Firestore 트랜잭션으로 동시성 문제 해결
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(productRef);

        if (!snapshot.exists) {
          throw Exception('상품을 찾을 수 없습니다');
        }

        final data = snapshot.data()!;
        final currentLikeUids = List<String>.from(data['likeUids'] ?? []);
        final currentLikeCount = data['likeCount'] as int? ?? 0;

        bool newIsFavorite;
        int newLikeCount;

        if (currentLikeUids.contains(uid)) {
          // 좋아요 취소
          currentLikeUids.remove(uid);
          newLikeCount = currentLikeCount > 0 ? currentLikeCount - 1 : 0;
          newIsFavorite = false;
        } else {
          // 좋아요 추가
          currentLikeUids.add(uid);
          newLikeCount = currentLikeCount + 1;
          newIsFavorite = true;
        }

        // Firestore 업데이트
        transaction.update(productRef, {
          'likeUids': currentLikeUids,
          'likeCount': newLikeCount,
        });

        // 로컬 상태 업데이트
        if (mounted) {
          setState(() {
            isFavorite = newIsFavorite;
            likeCount = newLikeCount;
          });
        }
      });

      // 성공 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite ? '관심 목록에 추가되었습니다' : '관심 목록에서 제거되었습니다',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      // 에러 발생 시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: ${e.toString()}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 시간 차이 계산
  String _getTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${difference.inDays ~/ 7}주 전';
    }
  }

  /// 가격 포맷팅
  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}원';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이미지 갤러리
                    _buildImageGallery(),

                    // 상품 정보
                    _buildProductInfo(),
                  ],
                ),
              ),
            ),

            // 하단 액션바
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  /// Header (뒤로가기 버튼)
  Widget _buildHeader() {
    return Container(
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF333333),
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 이미지 갤러리
  Widget _buildImageGallery() {
    final hasImages = widget.product.imageUrls.isNotEmpty;
    final imageCount = widget.product.imageUrls.length;

    return Container(
      height: 280,
      color: const Color(0xFFF2F2F2),
      child: Stack(
        children: [
          // 이미지 PageView
          if (hasImages)
            PageView.builder(
              itemCount: imageCount,
              onPageChanged: (index) {
                setState(() {
                  currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: widget.product.imageUrls[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFFE6E6E6),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFF6626),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFFE6E6E6),
                    child: const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Color(0xFF999999),
                        size: 48,
                      ),
                    ),
                  ),
                );
              },
            )
          else
            // 플레이스홀더
            Container(
              color: const Color(0xFFE6E6E6),
              child: const Center(
                child: Text(
                  '📷 상품 이미지',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            ),

          // 페이지 인디케이터
          if (hasImages && imageCount > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${currentImageIndex + 1}/$imageCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 상품 정보
  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),

          // 상품 제목
          Text(
            widget.product.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),

          // 카테고리, 위치, 시간
          Text(
            '${widget.product.category} · ${widget.product.location} · ${_getTimeAgo(widget.product.createdAt)}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF808080),
            ),
          ),
          const SizedBox(height: 12),

          // 상품 가격
          Text(
            _formatPrice(widget.product.price),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),

          // 상품 설명
          Text(
            widget.product.description,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF4D4D4D),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // 조회수, 관심수
          Text(
            '조회 ${widget.product.viewCount}  관심 $likeCount',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF808080),
            ),
          ),
        ],
      ),
    );
  }

  /// 하단 액션바
  Widget _buildBottomActionBar() {
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFF2F2F2),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // 하트 아이콘 (관심 등록)
          GestureDetector(
            onTap: _toggleLike,
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: Text(
                isFavorite ? '❤️' : '🤍',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 채팅하기 버튼
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  // 로그인 확인
                  final currentUser = _auth.currentUser;
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('로그인이 필요한 기능입니다'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Color(0xFFFF6626),
                      ),
                    );
                    return;
                  }

                  // 자기 자신의 상품인 경우
                  if (currentUser.uid == widget.product.sellerId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('자신의 상품은 채팅할 수 없습니다'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Color(0xFFFF6626),
                      ),
                    );
                    return;
                  }

                  // 채팅방 생성 또는 가져오기
                  try {
                    await _createOrGetChatRoom(currentUser.uid);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('채팅방 생성 중 오류가 발생했습니다: ${e.toString()}'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6626),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '채팅하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
