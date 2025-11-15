import '../entities/message_entity.dart';

/// 메시지 Repository 인터페이스
abstract class MessageRepository {
  /// 메시지 전송
  Future<String> sendMessage(MessageEntity message);

  /// 메시지 조회 (Stream)
  Stream<List<MessageEntity>> getMessages(String chatId);

  /// 메시지 읽음 처리 (단일)
  Future<void> markMessageAsRead({
    required String chatId,
    required String messageId,
  });

  /// 메시지 읽음 처리 (일괄 처리 - Batch Write)
  Future<void> markMessagesAsRead({
    required String chatId,
    required List<String> messageIds,
  });

  /// 상대방이 보낸 읽지 않은 메시지 조회
  Future<List<MessageEntity>> getUnreadMessages({
    required String chatId,
    required String currentUserId,
  });

  /// 메시지 삭제
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  });
}
