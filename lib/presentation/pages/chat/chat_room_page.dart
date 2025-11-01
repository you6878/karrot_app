import 'package:flutter/material.dart';
import 'package:karrot_clone/domain/entities/product.dart';

class ChatRoomPage extends StatefulWidget {
  final Product product;
  final String partnerId;
  final String partnerName;

  const ChatRoomPage({
    super.key,
    required this.product,
    required this.partnerId,
    required this.partnerName,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 임시 메시지 리스트 (추후 Firebase 연동)
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 초기 메시지 로드 (임시 데이터)
  void _loadInitialMessages() {
    setState(() {
      _messages.addAll([
        ChatMessage(
          id: '1',
          senderId: widget.partnerId,
          message: '안녕하세요! 게시하신 ${widget.product.title} 아직 판매중인가요?',
          sentAt: DateTime.now().subtract(const Duration(minutes: 18)),
          isMine: false,
        ),
        ChatMessage(
          id: '2',
          senderId: 'me',
          message: '네! 맞습니다. 언제 보러 오실 수 있나요?',
          sentAt: DateTime.now().subtract(const Duration(minutes: 17)),
          isMine: true,
        ),
        ChatMessage(
          id: '3',
          senderId: widget.partnerId,
          message: '오늘 오후 2시쯤 어떠세요? 집 근처에서 만날까요?',
          sentAt: DateTime.now().subtract(const Duration(minutes: 15)),
          isMine: false,
        ),
        ChatMessage(
          id: '4',
          senderId: 'me',
          message: '좋아요! 2시에 만나요',
          sentAt: DateTime.now().subtract(const Duration(minutes: 14)),
          isMine: true,
        ),
        ChatMessage(
          id: '5',
          senderId: widget.partnerId,
          message: '네! 그럼 주소 알려드릴게요 😊',
          sentAt: DateTime.now().subtract(const Duration(minutes: 13)),
          isMine: false,
        ),
      ]);
    });

    // 스크롤을 맨 아래로
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  /// 메시지 전송
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'me',
        message: text,
        sentAt: DateTime.now(),
        isMine: true,
      ));
    });

    _messageController.clear();

    // 스크롤을 맨 아래로
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Header
            _buildHeader(),

            // Messages Container
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
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
  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            message.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 메시지 버블
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: message.isMine
                  ? const Color(0xFFFF9933)
                  : const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              message.message,
              style: TextStyle(
                fontSize: 14,
                color: message.isMine ? Colors.white : const Color(0xFF333333),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // 시간 표시
          Text(
            _formatTime(message.sentAt),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF999999),
            ),
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

/// 채팅 메시지 모델 (임시)
class ChatMessage {
  final String id;
  final String senderId;
  final String message;
  final DateTime sentAt;
  final bool isMine;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.message,
    required this.sentAt,
    required this.isMine,
  });
}
