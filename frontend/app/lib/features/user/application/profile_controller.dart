import "package:candle_frontend/common/utils/string_extension.dart";
import "../../auth/application/session_controller.dart";
import "package:dart_scope_functions/dart_scope_functions.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "profile_state.dart";
import "user_controller.dart";
import "../domain/models/user.dart";

part "profile_controller.g.dart";

@riverpod
class ProfileController extends _$ProfileController {
  @override
  Future<ProfileState> build() async {
    // Credential changes must not discard an unsaved username edit.
    final identity = await ref.watch(
      userControllerProvider.selectAsync(
        (u) => (id: u.id, username: u.username, createdAt: u.createdAt),
      ),
    );
    final user = User(id: identity.id, username: identity.username, createdAt: identity.createdAt);

    return ProfileState(original: user, draft: user);
  }

  void usernameChanged(String username) =>
      _edit((it) => it.copyWith(username: username.trim().nullIfEmpty()));

  /// Watching the user means saving it rebuilds this controller with the saved
  /// version as the new original, so the form stops being dirty on its own.
  Future<User> save() async {
    final draft = state.value?.draft;

    if (draft == null) throw StateError("the profile is not loaded");

    return ref.read(userControllerProvider.notifier).save(draft);
  }

  Future<void> refresh() async {
    ref.read(userControllerProvider.notifier).refresh();

    await ref.read(userControllerProvider.future);
  }

  void logout() => ref.read(sessionControllerProvider.notifier).logout();

  void _edit(User Function(User draft) change) => state.value?.let(
    (it) => state = AsyncValue.data(it.copyWith(draft: change(it.draft))),
  );
}
