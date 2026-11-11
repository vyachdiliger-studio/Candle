import "/core/security/session_epoch.dart";

import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../auth/application/session_controller.dart";
import "../../auth/application/session_state.dart";
import "/features/user/domain/models/user.dart";
import "/features/user/domain/remote_user_repository.dart";
import "../data/dio_user_repository.dart";

part "user_controller.g.dart";

/// Kept alive: this is who the user is, not a screen's state. As autoDispose it
/// died with the profile screen and refetched on every visit.
@Riverpod(keepAlive: true)
class UserController extends _$UserController {
  @override
  Future<User> build() async {
    ref.watch(sessionEpochProvider);
    final operationRef = ref;
    final session = await ref.watch(sessionControllerProvider.future);

    if (session is! SessionAuth) throw StateError("no session");

    if (!operationRef.mounted) throw const SessionChanged();
    final result = await _repository.getMe();
    if (!operationRef.mounted) throw const SessionChanged();

    return result.fold(
      (_) => throw Exception("failed to load the user"),
      (user) => user,
    );
  }

  void refresh() => ref.invalidateSelf(asReload: true);

  Future<void> setPassword({String? currentPassword, required String newPassword}) async {
    final operationRef = ref;
    await _repository.setPassword(currentPassword: currentPassword, newPassword: newPassword);
    if (!operationRef.mounted) throw const SessionChanged();
    final user = state.value;
    if (user != null) state = AsyncData(user.copyWith(hasPassword: true));
  }

  /// Takes the whole draft rather than one field, so a new editable field is a
  /// line here and nothing anywhere else.
  Future<User> save(User draft) async {
    final operationRef = ref;
    final result = await _repository.updateMe(username: draft.username);

    if (!operationRef.mounted) throw const SessionChanged();
    return result.fold((_) => throw Exception("failed to update the user"), (
      user,
    ) {
      state = AsyncValue.data(user);

      return user;
    });
  }

  Future<void> deleteMe() async {
    final operationRef = ref;
    final result = await _repository.deleteMe();
    if (!operationRef.mounted) return;

    result.fold(
      (_) => throw Exception("failed to delete the user"),
      (_) => null,
    );

    await ref.read(sessionControllerProvider.notifier).logout();
  }

  RemoteUserRepository get _repository => ref.read(userRepositoryProvider);
}
