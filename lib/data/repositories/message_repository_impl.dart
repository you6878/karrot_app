import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/remote/message_remote_datasource.dart';
import '../models/message_model.dart';

/// 메시지 Repository 구현체
class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource _remoteDataSource;

  MessageRepositoryImpl({
    required MessageRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<String> sendMessage(MessageEntity message) async {
    try {
      final messageModel = MessageModel(
        id: message.id,
        chatId: message.chatId,
        senderId: message.senderId,
        content: message.content,
        type: message.type,
        sentAt: message.sentAt,
        isRead: message.isRead,
        imageUrl: message.imageUrl,
      );

      return await _remoteDataSource.sendMessage(
        chatId: message.chatId,
        message: messageModel,
      );
    } catch (e) {
      throw Exception('메시지 전송 실패: $e');
    }
  }

  @override
  Stream<List<MessageEntity>> getMessages(String chatId) {
    try {
      return _remoteDataSource.getMessages(chatId).map(
            (messages) => messages.map((model) => model.toEntity()).toList(),
          );
    } catch (e) {
      throw Exception('메시지 조회 실패: $e');
    }
  }

  @override
  Future<void> markMessageAsRead({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await _remoteDataSource.markMessageAsRead(
        chatId: chatId,
        messageId: messageId,
      );
    } catch (e) {
      throw Exception('메시지 읽음 처리 실패: $e');
    }
  }

  @override
  Future<void> markMessagesAsRead({
    required String chatId,
    required List<String> messageIds,
  }) async {
    try {
      await _remoteDataSource.markMessagesAsRead(
        chatId: chatId,
        messageIds: messageIds,
      );
    } catch (e) {
      throw Exception('메시지 일괄 읽음 처리 실패: $e');
    }
  }

  @override
  Future<List<MessageEntity>> getUnreadMessages({
    required String chatId,
    required String currentUserId,
  }) async {
    try {
      final messages = await _remoteDataSource.getUnreadMessages(
        chatId: chatId,
        currentUserId: currentUserId,
      );
      return messages.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('읽지 않은 메시지 조회 실패: $e');
    }
  }

  @override
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await _remoteDataSource.deleteMessage(
        chatId: chatId,
        messageId: messageId,
      );
    } catch (e) {
      throw Exception('메시지 삭제 실패: $e');
    }
  }
}
