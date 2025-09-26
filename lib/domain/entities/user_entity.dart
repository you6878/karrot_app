import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String nickname;
  final String? profileImageUrl;
  final String phone;
  final String? location;
  final double mannerTemperature;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLocationVerified;

  const UserEntity({
    required this.id,
    required this.email,
    required this.nickname,
    this.profileImageUrl,
    required this.phone,
    this.location,
    this.mannerTemperature = 36.5,
    required this.createdAt,
    required this.updatedAt,
    this.isLocationVerified = false,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        nickname,
        profileImageUrl,
        phone,
        location,
        mannerTemperature,
        createdAt,
        updatedAt,
        isLocationVerified,
      ];
}
