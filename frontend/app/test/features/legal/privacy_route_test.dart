import "dart:async";

import "package:candle_frontend/app/router.dart";
import "package:candle_frontend/features/auth/auth.dart";
import "package:candle_frontend/core/security/tokens.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";

class ControlledSession extends SessionController {
  @override
  Future<SessionState> build() => Completer<SessionState>().future;

  void setSession(AsyncValue<SessionState> value) => state = value;
}

void main() {
  testWidgets("Privacy remains accessible through session loading, failure and logout", (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(ControlledSession.new),
      ],
    );
    final router = container.read(routerProvider);
    router.go("/privacy");
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
    final session = container.read(sessionControllerProvider.notifier) as ControlledSession;
    for (final value in <AsyncValue<SessionState>>[
      const AsyncLoading(),
      AsyncError(Exception("offline"), StackTrace.current),
      const AsyncData(SessionState.guest()),
      AsyncData(SessionState.auth(Tokens(access: "access", refresh: "refresh"), 1)),
      const AsyncData(SessionState.guest()),
    ]) {
      session.setSession(value);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, "/privacy");
      expect(find.text("Privacy Policy"), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    container.dispose();
  });
}
