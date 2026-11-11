import "package:candle_frontend/core/security/tokens.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "session_state.freezed.dart";

@freezed
sealed class SessionState with _$SessionState {
  const factory SessionState.guest() = SessionGuest;
  const factory SessionState.auth(Tokens tokens, int userId) = SessionAuth;
}
