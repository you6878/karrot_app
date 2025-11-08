import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';
import '../repositories/user_repository.dart';

class CreateChatUseCase {
  final ChatRepository _chatRepository;
  final UserRepository _userRepository;

  CreateChatUseCase({
    required ChatRepository chatRepository,
    required UserRepository userRepository,
  })  : _chatRepository = chatRepository,
        _userRepository = userRepository;

  /// 채팅방 생성 (유저 정보 자동 포함)
  Future<ChatEntity> call({
    required String productId,
    required String buyerId,
    required String sellerId,
  }) async {
    try {
      // 1. 기존 채팅방이 있는지 확인
      final existingChat = await _chatRepository.findExistingChat(
        productId: productId,
        buyerId: buyerId,
        sellerId: sellerId,
      );

      if (existingChat != null) {
        return existingChat;
      }

      // 2. 구매자와 판매자 정보 조회
      final buyer = await _userRepository.getUserById(buyerId);
      final seller = await _userRepository.getUserById(sellerId);

      if (buyer == null) {
        throw Exception('구매자 정보를 찾을 수 없습니다.');
      }

      if (seller == null) {
        throw Exception('판매자 정보를 찾을 수 없습니다.');
      }

      // 3. participants 맵 생성
      final participants = <String, ParticipantInfo>{
        buyerId: ParticipantInfo(
          name: buyer.nickname,
          profileImg: buyer.profileImageUrl,
        ),
        sellerId: ParticipantInfo(
          name: seller.nickname,
          profileImg: seller.profileImageUrl,
        ),
      };

      // 4. 채팅방 생성
      final chat = await _chatRepository.createChat(
        productId: productId,
        buyerId: buyerId,
        sellerId: sellerId,
        participants: participants,
      );

      return chat;
    } catch (e) {
      throw Exception('채팅방 생성 실패: $e');
    }
  }
}



