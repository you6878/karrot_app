import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/remote/chat_remote_datasource.dart';
import '../models/chat_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl({ChatRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? ChatRemoteDataSource();

  @override
  Future<ChatEntity> createChat({
    required String productId,
    required String buyerId,
    required String sellerId,
    required Map<String, ParticipantInfo> participants,
  }) async {
    try {
      // Entity의 ParticipantInfo를 Model의 ParticipantInfoModel로 변환
      final participantsModel = <String, ParticipantInfoModel>{};
      participants.forEach((key, value) {
        participantsModel[key] = ParticipantInfoModel(
          name: value.name,
          profileImg: value.profileImg,
        );
      });

      final chatModel = await _remoteDataSource.createChat(
        productId: productId,
        buyerId: buyerId,
        sellerId: sellerId,
        participants: participantsModel,
      );

      return chatModel.toEntity();
    } catch (e) {
      throw Exception('채팅방 생성 실패: $e');
    }
  }

  @override
  Future<List<ChatEntity>> getChatList(String userId) async {
    try {
      final chatModels = await _remoteDataSource.getChatList(userId);
      return chatModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('채팅방 목록 조회 실패: $e');
    }
  }

  @override
  Future<ChatEntity?> getChatById(String chatId) async {
    try {
      final chatModel = await _remoteDataSource.getChatById(chatId);
      return chatModel?.toEntity();
    } catch (e) {
      throw Exception('채팅방 조회 실패: $e');
    }
  }

  @override
  Future<void> updateChat(ChatEntity chat) async {
    try {
      // Entity를 Model로 변환
      final participantsModel = <String, ParticipantInfoModel>{};
      chat.participants.forEach((key, value) {
        participantsModel[key] = ParticipantInfoModel(
          name: value.name,
          profileImg: value.profileImg,
        );
      });

      final chatModel = ChatModel(
        id: chat.id,
        productId: chat.productId,
        buyerId: chat.buyerId,
        sellerId: chat.sellerId,
        lastMessage: chat.lastMessage,
        unreadCount: chat.unreadCount,
        createdAt: chat.createdAt,
        updatedAt: chat.updatedAt,
        isActive: chat.isActive,
        participants: participantsModel,
      );

      await _remoteDataSource.updateChat(chatModel);
    } catch (e) {
      throw Exception('채팅방 업데이트 실패: $e');
    }
  }

  @override
  Future<void> updateLastMessage({
    required String chatId,
    required String lastMessage,
    required DateTime updatedAt,
  }) async {
    try {
      await _remoteDataSource.updateLastMessage(
        chatId: chatId,
        lastMessage: lastMessage,
        updatedAt: updatedAt,
      );
    } catch (e) {
      throw Exception('마지막 메시지 업데이트 실패: $e');
    }
  }

  @override
  Future<void> updateUnreadCount({
    required String chatId,
    required int unreadCount,
  }) async {
    try {
      await _remoteDataSource.updateUnreadCount(
        chatId: chatId,
        unreadCount: unreadCount,
      );
    } catch (e) {
      throw Exception('읽지 않은 메시지 수 업데이트 실패: $e');
    }
  }

  @override
  Future<void> deactivateChat(String chatId) async {
    try {
      await _remoteDataSource.deactivateChat(chatId);
    } catch (e) {
      throw Exception('채팅방 비활성화 실패: $e');
    }
  }

  @override
  Future<ChatEntity?> findExistingChat({
    required String productId,
    required String buyerId,
    required String sellerId,
  }) async {
    try {
      final chatModel = await _remoteDataSource.findExistingChat(
        productId: productId,
        buyerId: buyerId,
        sellerId: sellerId,
      );
      return chatModel?.toEntity();
    } catch (e) {
      throw Exception('기존 채팅방 찾기 실패: $e');
    }
  }
}



