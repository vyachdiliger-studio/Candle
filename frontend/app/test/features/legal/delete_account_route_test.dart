import "dart:async";

import "package:candle_frontend/app/router.dart";
import "package:candle_frontend/core/security/tokens.dart";
import "package:candle_frontend/features/auth/auth.dart";
import "package:candle_frontend/features/user/application/user_controller.dart";
import "package:candle_frontend/features/user/domain/models/user.dart";
import "package:candle_frontend/features/user/presentation/screens/profile_screen.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";

class ControlledSession extends SessionController {
  @override
  Future<SessionState> build() => Completer<SessionState>().future;

  void setSession(AsyncValue<SessionState> value) => state = value;
}

class TestUser extends UserController {
  @override
  Future<User> build() async => User(id: 1, createdAt: DateTime.utc(2026), username: "test");
}

void main() {
  for (final offline in [false, true]) {
    testWidgets("account deletion link resumes after sign-in (offline=$offline)", (tester) async {
      final container = ProviderContainer(
        overrides: [
          sessionControllerProvider.overrideWith(ControlledSession.new),
          userControllerProvider.overrideWith(TestUser.new),
        ],
      );
      final router = container.read(routerProvider);
      final session = container.read(sessionControllerProvider.notifier) as ControlledSession;
      if (offline) session.setSession(AsyncError(Exception("offline"), StackTrace.current));
      router.go("/delete-account");
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );

      session.setSession(
        offline
            ? AsyncError(Exception("offline"), StackTrace.current)
            : const AsyncData(SessionState.guest()),
      );
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, "/login");
      expect(router.routeInformationProvider.value.uri.queryParameters["from"], "/delete-account");

      session.setSession(
        AsyncData(SessionState.auth(Tokens(access: "access", refresh: "refresh"), 1)),
      );
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, "/profile");
      expect(find.byType(ProfileScreen), findsOneWidget);
      // Opening the link must not execute deletion or open a destructive dialog.
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      router.dispose();
      container.dispose();
    });
  }
}
