import "package:candle_frontend/core/errors/app_failure.dart";
import "dart:async";

import "package:flutter/foundation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:telegram_login/telegram_login.dart";

import "/core/config/app_config.dart";
import "../data/telegram/browser_login.dart";
import "../data/telegram/mini_app_init_data.dart";
import "auth_failure.dart";
import "google_sign_in_provider.dart";
import "session_controller.dart";

import "login_state.dart";

export "login_state.dart";

part "login_controller.g.dart";

@riverpod
class LoginController extends _$LoginController {
  final _telegram = TelegramLogin();

  bool get isMiniApp => telegramInitData.isNotEmpty;
  bool get telegramAvailable =>
      isMiniApp ||
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  LoginState build() {
    if (kIsWeb) {
      var disposed = false;
      StreamSubscription<GoogleSignInAuthenticationEvent>? subscription;
      ref.onDispose(() {
        disposed = true;
        unawaited(subscription?.cancel());
      });
      unawaited(() async {
        try {
          final google = await ref.read(googleSignInProvider.future);
          if (disposed) return;
          subscription = google.authenticationEvents.listen(
            (event) {
              if (event is GoogleSignInAuthenticationEventSignIn) {
                unawaited(_run(LoginMethod.google, () => _finishGoogle(event.user)));
              }
            },
            onError: (Object error) {
              if (!disposed) _showError(error);
            },
          );
        } catch (error) {
          if (!disposed) _showError(error);
        }
      }());
    }
    ref.onDispose(() {
      if (!kIsWeb && telegramAvailable) {
        unawaited(_telegram.cancelLogin().then<void>((_) {}, onError: (Object _) {}));
      }
    });
    return const LoginState();
  }

  void usernameChanged(String value) => state = state.copyWith(username: value);
  void passwordChanged(String value) => state = state.copyWith(password: value);
  void policyAcceptedChanged(bool value) => state = state.copyWith(policyAccepted: value);

  Future<void> loginWithPassword() async {
    if (state.busy) return;
    if (state.username.isEmpty || state.password.length < 6) {
      state = state.copyWith(
        passwordError: AppFailure.loginFieldsRequired,
      );
      return;
    }
    await _run(
      LoginMethod.password,
      () => ref
          .read(sessionControllerProvider.notifier)
          .loginWithPassword(state.username, state.password),
    );
  }

  Future<void> loginWithTelegram() => _run(LoginMethod.telegram, () async {
    final session = ref.read(sessionControllerProvider.notifier);
    if (isMiniApp) {
      await session.loginWithTelegram(telegramInitData);
      return;
    }
    if (kIsWeb) {
      // Keep the popup in the click call stack, before the first await.
      final token = await loginWithTelegramWeb(AppConfig.telegramClientId);
      if (ref.mounted && token != null) await session.loginWithTelegramToken(token);
      return;
    }
    final appUrl = defaultTargetPlatform == TargetPlatform.android
        ? AppConfig.telegramAndroidAppUrl
        : AppConfig.telegramIosAppUrl;
    if (appUrl.isEmpty || AppConfig.telegramClientId.isEmpty) {
      throw AppFailure.telegramNotConfigured;
    }
    await session.waitForLogout();
    if (!ref.mounted) return;
    await _telegram.configure(
      TelegramLoginConfiguration(
        clientId: AppConfig.telegramClientId,
        redirectUri: appUrl,
        scopes: const ["openid", "profile"],
        fallbackScheme: "com.example.candleFrontend",
      ),
    );
    if (!ref.mounted) return;
    final result = await _telegram.login();
    if (ref.mounted) await session.loginWithTelegramToken(result.idToken);
  });

  Future<void> loginWithGoogle() => _run(LoginMethod.google, () async {
    await ref.read(sessionControllerProvider.notifier).waitForLogout();
    if (!ref.mounted) return;
    final google = await ref.read(googleSignInProvider.future);
    if (!ref.mounted) return;
    final account = await google.authenticate();
    if (ref.mounted) await _finishGoogle(account);
  });

  Future<void> _finishGoogle(GoogleSignInAccount account) async {
    final token = account.authentication.idToken;
    if (token == null || token.isEmpty) throw AppFailure.googleTokenMissing;
    final google = ref.read(googleSignInProvider.future);
    try {
      await ref.read(sessionControllerProvider.notifier).loginWithGoogle(token);
    } catch (_) {
      try {
        await (await google).signOut();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> _run(LoginMethod method, Future<void> Function() action) async {
    if (state.busy) return;
    if (!state.policyAccepted) {
      const message = AppFailure.policyRequired;
      state = state.copyWith(
        passwordError: method == LoginMethod.password ? message : null,
        error: method != LoginMethod.password ? message : null,
      );
      return;
    }
    state = state.copyWith(pending: method, passwordError: null, error: null);
    AppFailure? message;
    try {
      await action();
    } catch (error) {
      if (!_cancelled(error)) message = _message(error);
    } finally {
      if (ref.mounted) {
        state = state.copyWith(
          pending: null,
          passwordError: method == LoginMethod.password ? message : null,
          error: method != LoginMethod.password ? message : null,
        );
      }
    }
  }

  void _showError(Object error) {
    if (!_cancelled(error)) {
      state = state.copyWith(
        error: _message(error),
      );
    }
  }

  bool _cancelled(Object error) =>
      error is TelegramLoginError && error.code == TelegramLoginErrorCode.cancelled ||
      error is GoogleSignInException && error.code == GoogleSignInExceptionCode.canceled;

  AppFailure _message(Object error) => switch (error) {
    AppFailure() => error,
    TimeoutException() => AppFailure.telegramTimeout,
    _ => authFailure(error),
  };
}
