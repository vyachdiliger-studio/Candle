import "package:candle_frontend/core/errors/app_failure.dart";
import "dart:async";

import "package:candle_frontend/features/user/application/password_form_controller.dart";
import "package:candle_frontend/features/user/application/user_controller.dart";
import "package:candle_frontend/features/user/domain/models/user.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";

class PasswordUser extends UserController {
  int calls = 0;
  String? current;
  final pending = Completer<void>();

  @override
  Future<User> build() async => User(id: 1, username: "user", createdAt: DateTime.utc(2026));

  @override
  Future<void> setPassword({String? currentPassword, required String newPassword}) {
    calls++;
    current = currentPassword;
    return pending.future;
  }
}

void main() {
  test("password form validates confirmation and current password before saving once", () async {
    final user = PasswordUser();
    final container = ProviderContainer(
      overrides: [userControllerProvider.overrideWith(() => user)],
    );
    addTearDown(container.dispose);
    final provider = passwordFormControllerProvider(true);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    final controller = container.read(provider.notifier);
    controller.passwordChanged("new password 123");
    await controller.save();
    expect(container.read(provider).error, AppFailure.passwordMismatch);
    controller.confirmationChanged("new password 123");
    await controller.save();
    expect(container.read(provider).error, AppFailure.currentPasswordRequired);
    expect(user.calls, 0);
    controller.currentPasswordChanged("old password 123");
    final saving = controller.save();
    await controller.save();
    expect(user.calls, 1);
    expect(user.current, "old password 123");
    expect(container.read(provider).busy, isTrue);
    user.pending.complete();
    await saving;
    expect(container.read(provider).saved, isTrue);
    expect(container.read(provider).busy, isFalse);
  });
}
