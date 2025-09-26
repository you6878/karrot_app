import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends Equatable {
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

  const UserModel({
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

  // Entity로 변환
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      nickname: nickname,
      profileImageUrl: profileImageUrl,
      phone: phone,
      location: location,
      mannerTemperature: mannerTemperature,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isLocationVerified: isLocationVerified,
    );
  }

  // Entity에서 Model로 변환
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      nickname: entity.nickname,
      profileImageUrl: entity.profileImageUrl,
      phone: entity.phone,
      location: entity.location,
      mannerTemperature: entity.mannerTemperature,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isLocationVerified: entity.isLocationVerified,
    );
  }

  // Firestore에서 가져온 데이터를 Model로 변환
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      phone: json['phone'] as String,
      location: json['location'] as String?,
      mannerTemperature:
          (json['mannerTemperature'] as num?)?.toDouble() ?? 36.5,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      isLocationVerified: json['isLocationVerified'] as bool? ?? false,
    );
  }

  // Firestore에 저장할 데이터로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'phone': phone,
      'location': location,
      'mannerTemperature': mannerTemperature,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isLocationVerified': isLocationVerified,
    };
  }

  // copyWith 메서드
  UserModel copyWith({
    String? id,
    String? email,
    String? nickname,
    String? profileImageUrl,
    String? phone,
    String? location,
    double? mannerTemperature,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLocationVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      mannerTemperature: mannerTemperature ?? this.mannerTemperature,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLocationVerified: isLocationVerified ?? this.isLocationVerified,
    );
  }

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
