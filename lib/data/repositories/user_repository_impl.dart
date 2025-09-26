import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../../utils/constants/firebase_collections.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestore _firestore;

  UserRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createUser(UserEntity user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(user.id)
          .set(userModel.toJson());
    } catch (e) {
      throw Exception('사용자 생성 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<UserEntity?> getUserById(String id) async {
    try {
      final doc =
          await _firestore.collection(FirebaseCollections.users).doc(id).get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!).toEntity();
      }
      return null;
    } catch (e) {
      throw Exception('사용자 조회 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<UserEntity?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.users)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromJson(querySnapshot.docs.first.data()).toEntity();
      }
      return null;
    } catch (e) {
      throw Exception('사용자 조회 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<void> updateUser(UserEntity user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(user.id)
          .update(userModel.toJson());
    } catch (e) {
      throw Exception('사용자 정보 업데이트 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      await _firestore.collection(FirebaseCollections.users).doc(id).delete();
    } catch (e) {
      throw Exception('사용자 삭제 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<bool> isNicknameAvailable(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.users)
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      throw Exception('닉네임 중복 확인 중 오류가 발생했습니다: $e');
    }
  }
}
