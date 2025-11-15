import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/message_model.dart';
import '../../../utils/constants/firebase_collections.dart';

/// 메시지 Remote DataSource
class MessageRemoteDataSource {
  final FirebaseFirestore _firestore;

  MessageRemoteDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 메시지 전송
  Future<String> sendMessage({
    required String chatId,
    required MessageModel message,
  }) async {
    try {
      final messageRef = _firestore
          .collection(FirebaseCollections.chats)
          .doc(chatId)
          .collection(FirebaseCollections.messages)
          .doc();

      final messageWithId = MessageModel(
        id: messageRef.id,
        chatId: message.chatId,
        senderId: message.senderId,
        content: message.content,
        type: message.type,
        sentAt: message.sentAt,
        isRead: message.isRead,
        imageUrl: message.imageUrl,
      );

      await messageRef.set(messageWithId.toJson());
      return messageRef.id;
    } catch (e) {
      throw Exception('메시지 전송 실패: $e');
    }
  }

  /// 메시지 조회 (Stream)
  Stream<List<MessageModel>> getMessages(String chatId) {
    try {
      return _firestore
          .collection(FirebaseCollections.chats)
          .doc(chatId)
          .collection(FirebaseCollections.messages)
          .orderBy('sentAt', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return MessageModel.fromJson({
            ...data,
            'id': doc.id,
          });
        }).toList();
      });
    } catch (e) {
      throw Exception('메시지 조회 실패: $e');
    }
  }

  /// 메시지 읽음 처리 (단일)
  Future<void> markMessageAsRead({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await _firestore
          .collection(FirebaseCollections.chats)
          .doc(chatId)
          .collection(FirebaseCollections.messages)
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('메시지 읽음 처리 실패: $e');
    }
  }

  /// 메시지 읽음 처리 (일괄 처리 - Batch Write)
  /// 📊 최적화: 여러 메시지를 한 번의 Firestore Write로 처리
  Future<void> markMessagesAsRead({
    required String chatId,
    required List<String> messageIds,
  }) async {
    if (messageIds.isEmpty) return;

    try {
      // Batch Write 생성
      final batch = _firestore.batch();
      final messagesCollection = _firestore
          .collection(FirebaseCollections.chats)
          .doc(chatId)
          .collection(FirebaseCollections.messages);

      // 각 메시지를 batch에 추가
      for (final messageId in messageIds) {
        final messageRef = messagesCollection.doc(messageId);
        batch.update(messageRef, {'isRead': true});
      }

      // 한 번에 커밋
      await batch.commit();
    } catch (e) {
      throw Exception('메시지 일괄 읽음 처리 실패: $e');
    }
  }

  /// 상대방이 보낸 읽지 않은 메시지 조회
  Future<List<MessageModel>> getUnreadMessages({
    required String chatId,
    required String currentUserId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.chats)
          .doc(chatId)
          .collection(FirebaseCollections.messages)
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: currentUserId)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return MessageModel.fromJson({
          ...data,
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('읽지 않은 메시지 조회 실패: $e');
    }
  }

  /// 메시지 삭제
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await _firestore
          .collection(FirebaseCollections.chats)
          .doc(chatId)
          .collection(FirebaseCollections.messages)
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('메시지 삭제 실패: $e');
    }
  }
}
