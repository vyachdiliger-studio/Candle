import "package:dartz/dartz.dart";
import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:candle_frontend/core/network/dio_provider.dart";

import "../domain/remote_user_repository.dart";
import "../domain/models/user.dart";
import "models/user_dto.dart";

class DioUserRepository implements RemoteUserRepository {
  final Dio dio;

  const DioUserRepository(this.dio);

  @override
  Future<void> setPassword({String? currentPassword, required String newPassword}) async {
    await dio.put(
      "/users/me/password",
      data: {
        "currentPassword": ?currentPassword,
        "newPassword": newPassword,
      },
    );
  }

  @override
  Future<Either<Unit, User>> getMe() async {
    try {
      final result = await dio.get("/users/me");

      final dto = UserDto.fromJson(result.data);

      return right(dto.toDomain());
    } on DioException {
      return left(unit);
    } catch (_) {
      return left(unit);
    }
  }

  @override
  Future<Either<Unit, User>> updateMe({required String? username}) async {
    try {
      final result = await dio.patch(
        "/users/me",
        data: {"username": username},
      );

      final dto = UserDto.fromJson(result.data);

      return right(dto.toDomain());
    } on DioException {
      return left(unit);
    } catch (_) {
      return left(unit);
    }
  }

  @override
  Future<Either<Unit, Unit>> deleteMe() async {
    try {
      await dio.delete("/users/me");

      return right(unit);
    } on DioException {
      return left(unit);
    } catch (_) {
      return left(unit);
    }
  }
}

final userRepositoryProvider = Provider<RemoteUserRepository>((ref) {
  return DioUserRepository(ref.watch(dioProvider));
});
