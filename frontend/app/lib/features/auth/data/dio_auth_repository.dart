import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:candle_frontend/core/security/tokens.dart";
import "package:candle_frontend/core/network/base_dio_provider.dart";

import "../domain/auth_repository.dart";

class DioAuthRepository implements AuthRepository {
  final Dio dio;

  const DioAuthRepository(this.dio);

  @override
  Future<AuthSession> loginWithPassword({
    required String username,
    required String password,
  }) async {
    final res = await dio.post(
      "/auth/password",
      data: {"username": username, "password": password},
    );
    return _sessionOf(res.data);
  }

  @override
  Future<AuthSession> loginWithGoogle({required String idToken}) async {
    final res = await dio.post("/auth/google", data: {"idToken": idToken});

    return _sessionOf(res.data);
  }

  @override
  Future<AuthSession> loginWithTelegram({String? initData, String? idToken}) async {
    final res = await dio.post(
      "/auth/telegram",
      data: {"initData": ?initData, "idToken": ?idToken},
    );

    return _sessionOf(res.data);
  }

  @override
  Future<AuthSession> refresh({required String refreshToken}) async {
    final res = await dio.post(
      "/auth/refresh",
      data: {"refreshToken": refreshToken},
    );

    return _sessionOf(res.data);
  }

  AuthSession _sessionOf(dynamic data) => (
    tokens: Tokens(
      access: data["access"] as String,
      refresh: data["refresh"] as String,
    ),
    userId: data["userId"] as int,
  );

  @override
  Future<void> logout({required Tokens tokens}) async {
    Future<void> revoke(Tokens snapshot) async {
      await dio.post(
        "/auth/logout",
        data: {"refresh": snapshot.refresh},
        options: Options(headers: {"Authorization": "Bearer ${snapshot.access}"}),
      );
    }

    try {
      await revoke(tokens);
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) rethrow;
      // Refresh only the outgoing session; never write these tokens locally.
      final renewed = await refresh(refreshToken: tokens.refresh);
      await revoke(renewed.tokens);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final base = ref.watch(baseDioProvider);

  return DioAuthRepository(base);
});
