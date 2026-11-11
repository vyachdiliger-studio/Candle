import "dart:async";
import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "/core/security/token_store.dart";
import "/core/security/session_epoch.dart";
import "/core/storage/preferences_storage.dart";
import "/features/candle/application/gallery_preferences.dart";
import "../data/dio_auth_repository.dart";
import "../domain/auth_repository.dart";
import "google_sign_in_provider.dart";
import "session_state.dart";

part "session_controller.g.dart";

final identitySignOutProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    try {
      await (await ref.read(googleSignInProvider.future)).signOut();
    } catch (_) {}
  },
);

@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  TokenStore get _store => ref.read(tokenStoreProvider);
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  SessionEpoch get _scope => ref.read(sessionEpochProvider.notifier);
  Future<void>? _logoutWork;

  @override
  Future<SessionState> build() async {
    final store = _store;
    final repository = _repository;
    final scope = _scope;
    final epoch = scope.current;
    final tokens = await store.read();
    if (tokens == null) return const SessionState.guest();
    try {
      final session = await repository.refresh(refreshToken: tokens.refresh);
      if (!await store.saveIfCurrent(session.tokens, () => scope.current == epoch)) {
        return state.value ?? const SessionState.guest();
      }
      return SessionState.auth(session.tokens, session.userId);
    } on DioException catch (error) {
      if (scope.current != epoch) return state.value ?? const SessionState.guest();
      if (error.response?.statusCode == 401 || error.response?.statusCode == 403) {
        await store.clear();
        return const SessionState.guest();
      }
      // A network outage must not erase the saved login.
      rethrow;
    }
  }

  Future<void> waitForLogout() async {
    try {
      await _logoutWork;
    } catch (_) {
      // A transient disk error must not permanently block the login button.
      _logoutWork = null;
      await logout();
    }
  }

  Future<void> loginWithTelegram(String initData) =>
      _login(() => _repository.loginWithTelegram(initData: initData));

  Future<void> loginWithTelegramToken(String idToken) =>
      _login(() => _repository.loginWithTelegram(idToken: idToken));

  Future<void> loginWithGoogle(String idToken) =>
      _login(() => _repository.loginWithGoogle(idToken: idToken));

  Future<void> loginWithPassword(String username, String password) =>
      _login(() => _repository.loginWithPassword(username: username, password: password));

  Future<void> _login(Future<AuthSession> Function() authenticate) async {
    await waitForLogout();
    final store = _store;
    final scope = _scope;
    final epoch = scope.advance();
    // The login form owns progress/errors and stays mounted until success.
    state = const AsyncData(SessionState.guest());
    try {
      await store.clear();
      if (scope.current != epoch) return;
      final session = await authenticate();
      if (!await store.saveIfCurrent(session.tokens, () => scope.current == epoch)) return;
      if (ref.mounted && scope.current == epoch) {
        state = AsyncData(SessionState.auth(session.tokens, session.userId));
      }
    } catch (_) {
      if (ref.mounted && scope.current == epoch) rethrow;
    }
  }

  Future<void> logout() {
    if (_logoutWork != null) return _logoutWork!;
    final store = _store;
    final repository = _repository;
    final history = ref.read(galleryStorageProvider);
    final oldProfileStorage = ref.read(storageProvider.future);
    final signOutIdentity = ref.read(identitySignOutProvider);
    // Capture before any awaits: cleanup/revocation must never read a new login.
    final oldTokens = store.read();
    _scope.advance();
    final clearTokens = store.clear();
    state = const AsyncData(SessionState.guest());
    final work = () async {
      final tokens = await oldTokens;
      await clearTokens;
      await history.clearOnLogout();
      await (await oldProfileStorage).delete("user");
      await signOutIdentity();
      // Remote revocation uses the captured credentials, with no later local writes.
      if (tokens != null) {
        unawaited(
          repository.logout(tokens: tokens).catchError((Object error) {
            debugPrint("[Auth] Remote logout failed: ${error.runtimeType}");
          }),
        );
      }
    }();
    _logoutWork = work;
    // Do not permit a new login until local cleanup and identity sign-out finish.
    unawaited(
      work.then(
        (_) {
          if (identical(_logoutWork, work)) _logoutWork = null;
        },
        onError: (Object error, StackTrace _) {
          debugPrint("[Auth] Local logout cleanup failed: ${error.runtimeType}");
        },
      ),
    );
    return work;
  }
}
