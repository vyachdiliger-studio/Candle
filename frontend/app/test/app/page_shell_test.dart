import "package:candle_frontend/app/presentation/page_shell.dart";
import "package:candle_frontend/app/router.dart";
import "package:candle_frontend/features/auth/auth.dart";
import "package:candle_frontend/features/settings/application/app_build_info_provider.dart";
import "package:candle_frontend/features/settings/domain/app_build_info.dart";
import "package:candle_frontend/features/user/application/user_controller.dart";
import "package:candle_frontend/features/user/domain/models/user.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";

class GuestSession extends SessionController {
  @override
  Future<SessionState> build() async => const SessionState.guest();
}

class TestUser extends UserController {
  @override
  Future<User> build() async => User(id: 1, createdAt: DateTime.utc(2026), username: "test");
}

void main() {
  testWidgets("the real guest settings deep link returns to login", (tester) async {
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(GuestSession.new),
        userControllerProvider.overrideWith(TestUser.new),
        appBuildInfoProvider.overrideWith(
          (ref) async => const AppBuildInfo(version: "1", buildNumber: "5"),
        ),
      ],
    );
    final router = container.read(routerProvider);
    router.go("/settings");
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
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, "/settings");
    await tester.tap(find.byIcon(Icons.arrow_back).hitTestable());
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, "/login");
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    container.dispose();
  });

  Future<GoRouter> pumpRouter(
    WidgetTester tester, {
    String initialLocation = "/settings",
    Widget page = const Text("Settings content"),
    ExitCallback? onExit,
  }) async {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: "/", builder: (_, _) => const Text("Home")),
        GoRoute(path: "/login", builder: (_, _) => const Text("Login")),
        ShellRoute(
          builder: (_, _, child) => PageShell(title: "Settings", child: child),
          routes: [GoRoute(path: "/settings", builder: (_, _) => page, onExit: onExit)],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets("back from a direct settings link falls back to home", (tester) async {
    final router = await pumpRouter(tester);
    expect(router.canPop(), isFalse);
    await tester.tap(find.byIcon(Icons.arrow_back).hitTestable());
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, "/");
    expect(find.text("Home"), findsOneWidget);
  });

  testWidgets("back from pushed settings returns to the previous screen", (tester) async {
    final router = await pumpRouter(tester, initialLocation: "/login");
    router.push("/settings");
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back).hitTestable());
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, "/login");
    expect(find.text("Login"), findsOneWidget);
  });

  testWidgets("a page's PopScope handles back before root fallback", (tester) async {
    var handled = 0;
    final router = await pumpRouter(
      tester,
      page: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) handled++;
        },
        child: const Text("Editing"),
      ),
    );
    await tester.tap(find.byIcon(Icons.arrow_back).hitTestable());
    await tester.pumpAndSettle();
    expect(handled, 1);
    expect(router.routeInformationProvider.value.uri.path, "/settings");
    expect(find.text("Editing"), findsOneWidget);
  });

  testWidgets("a route's exit guard can veto the root fallback", (tester) async {
    var handled = 0;
    final router = await pumpRouter(
      tester,
      onExit: (_, _) {
        handled++;
        return false;
      },
    );
    await tester.tap(find.byIcon(Icons.arrow_back).hitTestable());
    await tester.pumpAndSettle();
    expect(handled, 1);
    expect(router.routeInformationProvider.value.uri.path, "/settings");
  });
}
