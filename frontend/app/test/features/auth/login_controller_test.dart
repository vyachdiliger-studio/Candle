import "package:candle_frontend/core/errors/app_failure.dart";
import "package:candle_frontend/l10n/generated/app_localizations.dart";
import "dart:async";

import "package:candle_frontend/features/auth/application/login_controller.dart";
import "package:candle_frontend/features/auth/application/session_controller.dart";
import "package:candle_frontend/features/auth/application/session_state.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:candle_frontend/features/auth/presentation/login_screen.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";

class TestSession extends SessionController {
  int calls = 0;
  String? username;
  Completer<void> attempt = Completer<void>();

  @override
  Future<SessionState> build() async => const SessionState.guest();

  @override
  Future<void> loginWithPassword(String username, String password) {
    calls++;
    this.username = username;
    return attempt.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("form preserves text on error and provider buttons follow password login", (
    tester,
  ) async {
    final session = TestSession();
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(() => session),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginScreen(),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).at(0), "MyUsername");
    await tester.enterText(find.byType(TextField).at(1), "long password 123");
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text("Continue"));
    await tester.pump();
    final request = RequestOptions(path: "/auth/password");
    session.attempt.completeError(
      DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 401, data: "invalid_credentials"),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("MyUsername"), findsOneWidget);
    expect(find.textContaining("Incorrect username"), findsOneWidget);
    expect(
      tester.getTopLeft(find.text("Continue")).dy,
      lessThan(tester.getTopLeft(find.text("Sign in with Telegram")).dy),
    );
    expect(
      tester.getTopLeft(find.text("Sign in with Telegram")).dy,
      lessThan(tester.getTopLeft(find.text("Sign in with Google")).dy),
    );
    await tester.pumpWidget(const SizedBox());
  });

  test("password validation, duplicate submit, failure and retry preserve the draft", () async {
    final session = TestSession();
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(() => session),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(loginControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(sessionControllerProvider.future);
    final controller = container.read(loginControllerProvider.notifier);

    await controller.loginWithPassword();
    expect(session.calls, 0);
    expect(container.read(loginControllerProvider).passwordError, isNotNull);

    controller.usernameChanged("MyUsername");
    controller.passwordChanged("long password 123");
    controller.policyAcceptedChanged(true);
    final first = controller.loginWithPassword();
    await controller.loginWithPassword();
    expect(session.calls, 1);
    expect(container.read(loginControllerProvider).pending, LoginMethod.password);

    final request = RequestOptions(path: "/auth/password");
    session.attempt.completeError(
      DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 401, data: "invalid_credentials"),
      ),
    );
    await first;
    expect(container.read(loginControllerProvider).busy, isFalse);
    expect(container.read(loginControllerProvider).passwordError, AppFailure.invalidCredentials);

    session.attempt = Completer<void>();
    final retry = controller.loginWithPassword();
    expect(session.username, "MyUsername");
    expect(session.calls, 2);
    session.attempt.complete();
    await retry;
    expect(container.read(loginControllerProvider).passwordError, isNull);
    expect(container.read(loginControllerProvider).busy, isFalse);
  });

  test("finishing a request after the form is disposed does not update disposed state", () async {
    final session = TestSession();
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(() => session),
      ],
    );
    container.listen(loginControllerProvider, (_, _) {});
    await container.read(sessionControllerProvider.future);
    final controller = container.read(loginControllerProvider.notifier);
    controller.usernameChanged("user");
    controller.passwordChanged("long password 123");
    controller.policyAcceptedChanged(true);
    final pending = controller.loginWithPassword();
    container.dispose();
    session.attempt.complete();
    await pending;
  });
}
