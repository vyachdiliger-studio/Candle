import "package:candle_frontend/core/errors/app_failure.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../auth/application/auth_failure.dart";
import "password_form_state.dart";
import "user_controller.dart";

part "password_form_controller.g.dart";

@riverpod
class PasswordFormController extends _$PasswordFormController {
  @override
  PasswordFormState build(bool hasPassword) => const PasswordFormState();

  void currentPasswordChanged(String value) => state = state.copyWith(currentPassword: value);
  void passwordChanged(String value) => state = state.copyWith(password: value);
  void confirmationChanged(String value) => state = state.copyWith(confirmation: value);

  Future<void> save() async {
    if (state.busy || state.saved) return;
    if (state.password.length < 6) {
      state = state.copyWith(error: AppFailure.passwordTooShort);
      return;
    }
    if (state.password != state.confirmation) {
      state = state.copyWith(error: AppFailure.passwordMismatch);
      return;
    }
    if (hasPassword && state.currentPassword.isEmpty) {
      state = state.copyWith(error: AppFailure.currentPasswordRequired);
      return;
    }
    state = state.copyWith(busy: true, error: null);
    try {
      await ref
          .read(userControllerProvider.notifier)
          .setPassword(
            currentPassword: hasPassword ? state.currentPassword : null,
            newPassword: state.password,
          );
      if (ref.mounted) state = state.copyWith(busy: false, saved: true);
    } catch (error) {
      if (ref.mounted) state = state.copyWith(busy: false, error: authFailure(error));
    }
  }
}
