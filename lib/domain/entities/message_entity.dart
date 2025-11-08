import 'package:equatable/equatable.dart';

enum MessageType { text, image, system }

class MessageEntity extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime sentAt;
  final bool isRead;
  final String? imageUrl;

  const MessageEntity({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.sentAt,
    required this.isRead,
    this.imageUrl,
  });

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



