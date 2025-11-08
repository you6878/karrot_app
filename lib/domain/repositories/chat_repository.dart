import '../entities/chat_entity.dart';

abstract class ChatRepository {
  /// 채팅방 생성
  Future<ChatEntity> createChat({
    required String productId,
    required String buyerId,
    required String sellerId,
    required Map<String, ParticipantInfo> participants,
  });

  /// 채팅방 목록 조회
  Future<List<ChatEntity>> getChatList(String userId);

  /// 특정 채팅방 조회
  Future<ChatEntity?> getChatById(String chatId);

  /// 채팅방 업데이트
  Future<void> updateChat(ChatEntity chat);

  /// 마지막 메시지 업데이트
  Future<void> updateLastMessage({
    required String chatId,
    required String lastMessage,
    required DateTime updatedAt,
  });

  /// 읽지 않은 메시지 수 업데이트
  Future<void> updateUnreadCount({
    required String chatId,
    required int unreadCount,
  });

  /// 채팅방 비활성화
  Future<void> deactivateChat(String chatId);

  /// 구매자와 판매자 간 기존 채팅방 찾기
  Future<ChatEntity?> findExistingChat({
    required String productId,
    required String buyerId,
    required String sellerId,
  });
}



