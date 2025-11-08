import 'package:equatable/equatable.dart';
import '../../domain/entities/message_entity.dart';

class MessageModel extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime sentAt;
  final bool isRead;
  final String? imageUrl;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.sentAt,
    required this.isRead,
    this.imageUrl,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      type: _parseMessageType(json['type'] as String?),
      sentAt: json['sentAt'] is DateTime
          ? json['sentAt'] as DateTime
          : DateTime.parse(json['sentAt'] as String),
      isRead: json['isRead'] as bool,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': _messageTypeToString(type),
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
    };
  }

  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      chatId: chatId,
      senderId: senderId,
      content: content,
      type: type,
      sentAt: sentAt,
      isRead: isRead,
      imageUrl: imageUrl,
    );
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? sentAt,
    bool? isRead,
    String? imageUrl,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        content,
        type,
        sentAt,
        isRead,
        imageUrl,
      ];
}

// Helper functions
MessageType _parseMessageType(String? type) {
  switch (type) {
    case 'text':
      return MessageType.text;
    case 'image':
      return MessageType.image;
    case 'system':
      return MessageType.system;
    default:
      return MessageType.text;
  }
}

String _messageTypeToString(MessageType type) {
  switch (type) {
    case MessageType.text:
      return 'text';
    case MessageType.image:
      return 'image';
    case MessageType.system:
      return 'system';
  }
}
