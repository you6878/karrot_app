import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_entity.dart';

class ParticipantInfoModel extends Equatable {
  final String name;
  final String? profileImg;

  const ParticipantInfoModel({
    required this.name,
    this.profileImg,
  });

  factory ParticipantInfoModel.fromJson(Map<String, dynamic> json) {
    return ParticipantInfoModel(
      name: json['name'] as String,
      profileImg: json['profileImg'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'profileImg': profileImg,
    };
  }

  ParticipantInfo toEntity() {
    return ParticipantInfo(
      name: name,
      profileImg: profileImg,
    );
  }

  ParticipantInfoModel copyWith({
    String? name,
    String? profileImg,
  }) {
    return ParticipantInfoModel(
      name: name ?? this.name,
      profileImg: profileImg ?? this.profileImg,
    );
  }

  @override
  List<Object?> get props => [name, profileImg];
}

class ChatModel extends Equatable {
  final String id;
  final String productId;
  final String buyerId;
  final String sellerId;
  final String? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, ParticipantInfoModel> participants;

  const ChatModel({
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

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final participantsMap = json['participants'] as Map<String, dynamic>;
    final parsedParticipants = <String, ParticipantInfoModel>{};
    
    participantsMap.forEach((key, value) {
      parsedParticipants[key] = ParticipantInfoModel.fromJson(
        value as Map<String, dynamic>,
      );
    });

    return ChatModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      buyerId: json['buyerId'] as String,
      sellerId: json['sellerId'] as String,
      lastMessage: json['lastMessage'] as String?,
      unreadCount: json['unreadCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool,
      participants: parsedParticipants,
    );
  }

  Map<String, dynamic> toJson() {
    final participantsJson = <String, dynamic>{};
    participants.forEach((key, value) {
      participantsJson[key] = value.toJson();
    });

    return {
      'id': id,
      'productId': productId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'participants': participantsJson,
    };
  }

  ChatEntity toEntity() {
    final participantsEntity = <String, ParticipantInfo>{};
    participants.forEach((key, value) {
      participantsEntity[key] = value.toEntity();
    });

    return ChatEntity(
      id: id,
      productId: productId,
      buyerId: buyerId,
      sellerId: sellerId,
      lastMessage: lastMessage,
      unreadCount: unreadCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
      participants: participantsEntity,
    );
  }

  ChatModel copyWith({
    String? id,
    String? productId,
    String? buyerId,
    String? sellerId,
    String? lastMessage,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, ParticipantInfoModel>? participants,
  }) {
    return ChatModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      participants: participants ?? this.participants,
    );
  }

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



