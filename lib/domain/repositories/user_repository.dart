import '../entities/user_entity.dart';

abstract class UserRepository {
  Future<void> createUser(UserEntity user);
  Future<UserEntity?> getUserById(String id);
  Future<UserEntity?> getUserByEmail(String email);
  Future<void> updateUser(UserEntity user);
  Future<void> deleteUser(String id);
  Future<bool> isNicknameAvailable(String nickname);
}
