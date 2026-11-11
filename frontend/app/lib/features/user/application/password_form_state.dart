import "package:candle_frontend/core/errors/app_failure.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "password_form_state.freezed.dart";

@freezed
abstract class PasswordFormState with _$PasswordFormState {
  const factory PasswordFormState({
    @Default("") String currentPassword,
    @Default("") String password,
    @Default("") String confirmation,
    @Default(false) bool busy,
    @Default(false) bool saved,
    AppFailure? error,
  }) = _PasswordFormState;
}
