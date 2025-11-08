import 'package:equatable/equatable.dart';

class ParticipantInfo extends Equatable {
  final String name;
  final String? profileImg;

  const ParticipantInfo({
    required this.name,
    this.profileImg,
  });

  @override
  List<Object?> get props => [name, profileImg];
}

class ChatEntity extends Equatable {
  final String id;
  final String productId;
  final String buyerId;
  final String sellerId;
  final String? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, ParticipantInfo> participants;

  const ChatEntity({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.participants,
  });

  @override
  List<Object?> get props => [
        id,
        productId,
        buyerId,
        sellerId,
        lastMessage,
        unreadCount,
        createdAt,
        updatedAt,
        isActive,
        participants,
      ];
}



