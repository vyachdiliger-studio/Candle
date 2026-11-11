import "package:candle_frontend/core/security/tokens.dart";

typedef AuthSession = ({Tokens tokens, int userId});

abstract class AuthRepository {
  Future<AuthSession> loginWithTelegram({String? initData, String? idToken});
  Future<AuthSession> loginWithGoogle({required String idToken});
  Future<AuthSession> loginWithPassword({required String username, required String password});
  Future<AuthSession> refresh({required String refreshToken});
  Future<void> logout({required Tokens tokens});
}
