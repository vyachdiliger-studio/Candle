import "package:dartz/dartz.dart";
import "models/user.dart";

abstract class RemoteUserRepository {
  Future<void> setPassword({String? currentPassword, required String newPassword});
  Future<Either<Unit, User>> getMe();
  Future<Either<Unit, User>> updateMe({required String? username});
  Future<Either<Unit, Unit>> deleteMe();
}
