import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:karrot_clone/domain/entities/product.dart';
import 'package:karrot_clone/presentation/pages/chat/chat_room_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// 시간 포맷팅
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // 오늘
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour < 12 ? '오전' : '오후';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$period $displayHour:$minute';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${dateTime.month}월 ${dateTime.day}일';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '채팅',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
      ),
      body: currentUser == null
          ? _buildLoginRequired()
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .where('isActive', isEqualTo: true)
                  .orderBy('updatedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildError(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoading();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmpty();
                }

                // 현재 사용자가 참여한 채팅만 필터링
                final userChats = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final participants =
                      data['participants'] as Map<String, dynamic>?;
                  return participants?.containsKey(currentUser.uid) ?? false;
                }).toList();

                if (userChats.isEmpty) {
                  return _buildEmpty();
                }

                return ListView.separated(
                  itemCount: userChats.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF5F5F5),
                  ),
                  itemBuilder: (context, index) {
                    final doc = userChats[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return _ChatListItem(
                      chatData: data,
                      chatId: doc.id,
                      currentUserId: currentUser.uid,
                      formatTime: _formatTime,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildLoginRequired() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🔒',
            style: TextStyle(fontSize: 48),
          ),
          SizedBox(height: 16),
          Text(
            '로그인이 필요합니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFFFF6F0F),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '❌',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            '오류가 발생했습니다',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF808080),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '💬',
            style: TextStyle(fontSize: 48),
          ),
          SizedBox(height: 16),
          Text(
            '채팅 내역이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '상품을 보고 채팅을 시작해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF808080),
            ),
          ),
        ],
      ),
    );
  }
}

/// ProductStatus 파싱 헬퍼 함수
ProductStatus _parseProductStatus(String? status) {
  switch (status) {
    case 'available':
      return ProductStatus.available;
    case 'reserved':
      return ProductStatus.reserved;
    case 'sold':
      return ProductStatus.sold;
    default:
      return ProductStatus.available;
  }
}

class _ChatListItem extends StatelessWidget {
  final Map<String, dynamic> chatData;
  final String chatId;
  final String currentUserId;
  final String Function(DateTime) formatTime;

  const _ChatListItem({
    required this.chatData,
    required this.chatId,
    required this.currentUserId,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    // 상대방 ID 찾기 (현재 사용자가 아닌 다른 참여자)
    final participants = chatData['participants'] as Map<String, dynamic>?;
    String? partnerId;
    String partnerName = '알 수 없는 사용자';
    String? partnerProfileImg;

    if (participants != null) {
      for (final entry in participants.entries) {
        if (entry.key != currentUserId) {
          partnerId = entry.key;
          final partnerData = entry.value as Map<String, dynamic>;
          partnerName = partnerData['name'] ?? '알 수 없는 사용자';
          partnerProfileImg = partnerData['profileImg'];
          break;
        }
      }
    }

    // 마지막 메시지
    final lastMessage = chatData['lastMessage'] as String? ?? '메시지 없음';

    // 읽지 않은 메시지 수
    final unreadCount = chatData['unreadCount'] as int? ?? 0;

    // 업데이트 시간
    final updatedAt = chatData['updatedAt'] is Timestamp
        ? (chatData['updatedAt'] as Timestamp).toDate()
        : (chatData['updatedAt'] is String
            ? DateTime.parse(chatData['updatedAt'] as String)
            : DateTime.now());

    final timeText = formatTime(updatedAt);

    return InkWell(
      onTap: () async {
        if (partnerId == null) return;

        // 상품 정보 가져오기
        final productId = chatData['productId'] as String?;
        if (productId == null) return;

        try {
          // Firestore에서 상품 정보 가져오기
          final productDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .get();

          if (!productDoc.exists) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('상품 정보를 찾을 수 없습니다'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          // Firestore 데이터를 Product 엔티티로 변환
          final productData = productDoc.data()!;
          final product = Product(
            id: productDoc.id,
            title: productData['title'] as String? ?? '',
            description: productData['description'] as String? ?? '',
            price: productData['price'] as int? ?? 0,
            imageUrls: (productData['imageUrls'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            category: productData['category'] as String? ?? '',
            sellerId: productData['sellerId'] as String? ?? '',
            location: productData['location'] as String? ?? '',
            longitude: (productData['longitude'] as num?)?.toDouble(),
            latitude: (productData['latitude'] as num?)?.toDouble(),
            status: _parseProductStatus(productData['status'] as String?),
            viewCount: productData['viewCount'] as int? ?? 0,
            likeCount: productData['likeCount'] as int? ?? 0,
            likeUids: (productData['likeUids'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            createdAt: productData['createdAt'] is Timestamp
                ? (productData['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            updatedAt: productData['updatedAt'] is Timestamp
                ? (productData['updatedAt'] as Timestamp).toDate()
                : DateTime.now(),
            isNegotiable: productData['isNegotiable'] as bool? ?? false,
          );

          // 채팅방으로 이동
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomPage(
                  product: product,
                  partnerId: partnerId!,
                  partnerName: partnerName,
                  chatId: chatId,
                ),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('채팅방을 불러오는데 실패했습니다: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 이미지
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: partnerProfileImg != null && partnerProfileImg.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        partnerProfileImg,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.person,
                              color: Color(0xFF999999),
                              size: 24,
                            ),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF999999),
                        size: 24,
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // 채팅 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 닉네임
                      Expanded(
                        child: Text(
                          partnerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 시간
                      Text(
                        timeText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 마지막 메시지
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6F0F),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // 상품 이미지
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('products')
                  .doc(chatData['productId'] as String?)
                  .get(),
              builder: (context, snapshot) {
                String? imageUrl;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final productData =
                      snapshot.data!.data() as Map<String, dynamic>?;
                  final imageUrls = productData?['imageUrls'] as List?;
                  if (imageUrls != null && imageUrls.isNotEmpty) {
                    imageUrl = imageUrls[0] as String?;
                  }
                }

                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.image,
                                  color: Color(0xFF999999),
                                  size: 24,
                                ),
                              );
                            },
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.image,
                            color: Color(0xFF999999),
                            size: 24,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
