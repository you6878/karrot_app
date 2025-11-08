import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chat_model.dart';

class ChatRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'chats';

  /// 채팅방 생성
  Future<ChatModel> createChat({
    required String productId,
    required String buyerId,
    required String sellerId,
    required Map<String, ParticipantInfoModel> participants,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = _firestore.collection(_collectionName).doc();

      final chatModel = ChatModel(
        id: docRef.id,
        productId: productId,
        buyerId: buyerId,
        sellerId: sellerId,
        lastMessage: null,
        unreadCount: 0,
        createdAt: now,
        updatedAt: now,
        isActive: true,
        participants: participants,
      );

      await docRef.set(chatModel.toJson());
      return chatModel;
    } catch (e) {
      throw Exception('채팅방 생성 실패: $e');
    }
  }

  /// 채팅방 목록 조회 (사용자 ID로)
  Future<List<ChatModel>> getChatList(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .where('participants.$userId', isNotEqualTo: null)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChatModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('채팅방 목록 조회 실패: $e');
    }
  }

  /// 특정 채팅방 조회
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final docSnapshot =
          await _firestore.collection(_collectionName).doc(chatId).get();

      if (!docSnapshot.exists) {
        return null;
      }

      return ChatModel.fromJson({...docSnapshot.data()!, 'id': docSnapshot.id});
    } catch (e) {
      throw Exception('채팅방 조회 실패: $e');
    }
  }

  /// 채팅방 업데이트
  Future<void> updateChat(ChatModel chat) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(chat.id)
          .update(chat.toJson());
    } catch (e) {
      throw Exception('채팅방 업데이트 실패: $e');
    }
  }

  /// 마지막 메시지 업데이트
  Future<void> updateLastMessage({
    required String chatId,
    required String lastMessage,
    required DateTime updatedAt,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(chatId).update({
        'lastMessage': lastMessage,
        'updatedAt': updatedAt.toIso8601String(),
      });
    } catch (e) {
      throw Exception('마지막 메시지 업데이트 실패: $e');
    }
  }

  /// 읽지 않은 메시지 수 업데이트
  Future<void> updateUnreadCount({
    required String chatId,
    required int unreadCount,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(chatId).update({
        'unreadCount': unreadCount,
      });
    } catch (e) {
      throw Exception('읽지 않은 메시지 수 업데이트 실패: $e');
    }
  }

  /// 채팅방 비활성화
  Future<void> deactivateChat(String chatId) async {
    try {
      await _firestore.collection(_collectionName).doc(chatId).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('채팅방 비활성화 실패: $e');
    }
  }

  /// 구매자와 판매자 간 기존 채팅방 찾기
  Future<ChatModel?> findExistingChat({
    required String productId,
    required String buyerId,
    required String sellerId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('productId', isEqualTo: productId)
          .where('buyerId', isEqualTo: buyerId)
          .where('sellerId', isEqualTo: sellerId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return ChatModel.fromJson({...doc.data(), 'id': doc.id});
    } catch (e) {
      throw Exception('기존 채팅방 찾기 실패: $e');
    }
  }
}



