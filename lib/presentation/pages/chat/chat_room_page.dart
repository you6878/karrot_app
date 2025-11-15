import 'package:flutter/material.dart';
import 'package:karrot_clone/domain/entities/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../data/models/message_model.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../data/datasources/remote/message_remote_datasource.dart';
import '../../../data/repositories/message_repository_impl.dart';
import '../../../domain/repositories/message_repository.dart';

class ChatRoomPage extends StatefulWidget {
  final Product product;
  final String partnerId;
  final String partnerName;
  final String? chatId; // chatId 추가 (옵셔널)

  const ChatRoomPage({
    super.key,
    required this.product,
    required this.partnerId,
    required this.partnerName,
    this.chatId,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  late final MessageRepository _messageRepository;
  String? _chatId;
  bool _isLoading = true;

  // 읽음 처리를 위한 이전 메시지 ID 목록
  Set<String> _previousMessageIds = {};

  @override
  void initState() {
    super.initState();
    // MessageRepository 초기화
    final messageDataSource = MessageRemoteDataSource(firestore: _firestore);
    _messageRepository = MessageRepositoryImpl(
      remoteDataSource: messageDataSource,
    );
    _initializeChatRoom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 채팅방 초기화
  Future<void> _initializeChatRoom() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // chatId가 제공된 경우 사용, 아니면 찾거나 생성
      if (widget.chatId != null) {
        _chatId = widget.chatId;
      } else {
        // productId, buyerId, sellerId로 기존 채팅방 찾기
        final querySnapshot = await _firestore
            .collection('chats')
            .where('productId', isEqualTo: widget.product.id)
            .where('isActive', isEqualTo: true)
            .get();

        // 현재 사용자와 파트너가 참여한 채팅방 찾기
        for (final doc in querySnapshot.docs) {
          final data = doc.data();
          final participants = data['participants'] as Map<String, dynamic>?;
          if (participants != null &&
              participants.containsKey(currentUser.uid) &&
              participants.containsKey(widget.partnerId)) {
            _chatId = doc.id;
            break;
          }
        }
      }

      setState(() {
        _isLoading = false;
      });

      // 채팅방 입장 시 안 읽은 메시지 자동 읽음 처리
      if (_chatId != null) {
        _markUnreadMessagesAsRead();
      }

      // 스크롤을 맨 아래로
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 📊 채팅방 입장 시 상대방이 보낸 안 읽은 메시지를 Batch로 읽음 처리
  Future<void> _markUnreadMessagesAsRead() async {
    if (_chatId == null) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // 상대방이 보낸 읽지 않은 메시지 조회
      final unreadMessages = await _messageRepository.getUnreadMessages(
        chatId: _chatId!,
        currentUserId: currentUser.uid,
      );

      if (unreadMessages.isEmpty) return;

      // 메시지 ID 목록 추출
      final messageIds = unreadMessages.map((msg) => msg.id).toList();

      // Batch Write로 한 번에 읽음 처리
      await _messageRepository.markMessagesAsRead(
        chatId: _chatId!,
        messageIds: messageIds,
      );

      // 이전 메시지 ID 목록 업데이트
      _previousMessageIds.addAll(messageIds);
    } catch (e) {
      // 에러 발생 시 무시 (사용자 경험에 영향 없음)
    }
  }

  /// 📊 실시간으로 새 메시지가 오면 자동으로 읽음 처리
  Future<void> _markNewMessagesAsRead(List<MessageModel> messages) async {
    if (_chatId == null || messages.isEmpty) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // 상대방이 보낸 새 메시지 중 읽지 않은 메시지 필터링
      final newUnreadMessages = messages.where((msg) {
        return msg.senderId != currentUser.uid &&
            !msg.isRead &&
            !_previousMessageIds.contains(msg.id);
      }).toList();

      if (newUnreadMessages.isEmpty) return;

      // 메시지 ID 목록 추출
      final messageIds = newUnreadMessages.map((msg) => msg.id).toList();

      // Batch Write로 한 번에 읽음 처리
      await _messageRepository.markMessagesAsRead(
        chatId: _chatId!,
        messageIds: messageIds,
      );

      // 이전 메시지 ID 목록 업데이트
      _previousMessageIds.addAll(messageIds);
    } catch (e) {
      // 에러 발생 시 무시 (사용자 경험에 영향 없음)
    }
  }

  /// 메시지 전송
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatId == null) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _messageController.clear();

    try {
      final now = DateTime.now();
      final messageRef = _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .doc();

      final messageModel = MessageModel(
        id: messageRef.id,
        chatId: _chatId!,
        senderId: currentUser.uid,
        content: text,
        type: MessageType.text,
        sentAt: now,
        isRead: false,
        imageUrl: null,
      );

      // 메시지 저장
      await messageRef.set(messageModel.toJson());

      // 채팅방의 lastMessage와 updatedAt 업데이트
      await _firestore.collection('chats').doc(_chatId).update({
        'lastMessage': text,
        'updatedAt': now.toIso8601String(),
      });

      // 스크롤을 맨 아래로
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('메시지 전송 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 스크롤을 맨 아래로
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// 시간 포맷팅
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? '오후' : '오전';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period ${hour == 0 ? 12 : hour}:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Header
            _buildHeader(),

            // Messages Container
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF6F0F),
                      ),
                    )
                  : _chatId == null
                      ? const Center(
                          child: Text('채팅방을 찾을 수 없습니다'),
                        )
                      : StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('chats')
                              .doc(_chatId)
                              .collection('messages')
                              .orderBy('sentAt', descending: false)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text('오류가 발생했습니다: ${snapshot.error}'),
                              );
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFF6F0F),
                                ),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text(
                                  '메시지가 없습니다\n첫 메시지를 보내보세요!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF999999),
                                  ),
                                ),
                              );
                            }

                            final messages = snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return MessageModel.fromJson({
                                ...data,
                                'id': doc.id,
                              });
                            }).toList();

                            // 📊 실시간으로 새 메시지 자동 읽음 처리
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _markNewMessagesAsRead(messages);
                              _scrollToBottom();
                            });

                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final isMine =
                                    message.senderId == currentUser?.uid;
                                return _buildMessageBubble(message, isMine);
                              },
                            );
                          },
                        ),
            ),

            // Input Container
            _buildInputContainer(),
          ],
        ),
      ),
    );
  }

  /// Chat Header
  Widget _buildHeader() {
    return Container(
      height: 88,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 뒤로가기 버튼
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF4D4D4D),
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),

          // 파트너 프로필 이미지
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF3399FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                widget.partnerName.isNotEmpty ? widget.partnerName[0] : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 채팅 제목
          Expanded(
            child: Text(
              '${widget.partnerName}님과의 대화',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ),

          // 더보기 메뉴
          IconButton(
            onPressed: () {
              // TODO: 더보기 메뉴
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('더보기 메뉴'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(
              Icons.more_horiz,
              color: Color(0xFF808080),
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 메시지 버블
  Widget _buildMessageBubble(MessageModel message, bool isMine) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 메시지 버블
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMine ? const Color(0xFFFF9933) : const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: isMine ? Colors.white : const Color(0xFF333333),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // 시간 표시
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!message.isRead && isMine)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Text(
                    '1',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFF6F0F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Text(
                _formatTime(message.sentAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Input Container
  Widget _buildInputContainer() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // 첨부 버튼
          GestureDetector(
            onTap: () {
              // TODO: 이미지 첨부
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('이미지 첨부 기능 개발 예정'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFE6E6E6),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Center(
                child: Icon(
                  Icons.add,
                  color: Color(0xFF999999),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 메시지 입력 필드
          Expanded(
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(17),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                ),
                decoration: const InputDecoration(
                  hintText: '메시지를 입력하세요...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 전송 버튼
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9933),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
