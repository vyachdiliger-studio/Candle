import "package:candle_frontend/core/errors/app_failure.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "login_state.freezed.dart";

enum LoginMethod { password, telegram, google }

@freezed
abstract class LoginState with _$LoginState {
  const LoginState._();

  const factory LoginState({
    @Default("") String username,
    @Default("") String password,
    @Default(false) bool policyAccepted,
    LoginMethod? pending,
    AppFailure? passwordError,
    AppFailure? error,
  }) = _LoginState;

  bool get busy => pending != null;
}
