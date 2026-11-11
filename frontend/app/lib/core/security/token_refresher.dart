import "package:flutter_riverpod/flutter_riverpod.dart";
import "tokens.dart";

abstract class TokenRefresher {
  Future<Tokens> refresh(String refreshToken);
}

final tokenRefresherProvider = Provider<TokenRefresher>((_) {
  throw UnimplementedError("Provide TokenRefresher via overrides in main.dart");
});
