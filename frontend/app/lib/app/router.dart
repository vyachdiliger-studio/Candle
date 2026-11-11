import "package:candle_frontend/features/settings/presentation/settings_screen.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "package:candle_frontend/features/auth/auth.dart";
import "package:candle_frontend/features/user/user.dart" show ProfileScreen;
import "package:candle_frontend/features/map/map.dart" show MapScreen;
import "package:candle_frontend/features/candle/presentation/screens/candle_gallery_screen.dart";
import "package:candle_frontend/features/legal/presentation/screens/privacy_policy_screen.dart";

import "presentation/app_shell.dart";
import "presentation/drawer_shell.dart";
import "presentation/page_shell.dart";
import "presentation/screens/splash_screen.dart";

class _GoRouterNotifier extends ChangeNotifier {
  final Ref ref;
  bool redirectAfterLogout = false;

  late final ProviderSubscription<AsyncValue<SessionState>> _subscription;

  _GoRouterNotifier(this.ref) {
    _subscription = ref.listen(
      sessionControllerProvider,
      (previous, next) {
        if (previous?.value is SessionAuth && next.value is SessionGuest) {
          redirectAfterLogout = true;
        }
        notifyListeners();
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _subscription.close();

    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _GoRouterNotifier(ref);

  ref.onDispose(notifier.dispose);

  String? redirect(BuildContext context, GoRouterState state) {
    final here = state.matchedLocation;
    if (here == "/privacy") return null;

    final sessionAsync = ref.read(sessionControllerProvider);

    // A pushed profile can sit above a public candle route. Signing out must
    // leave the entire authenticated stack, not reveal that route underneath.
    if (notifier.redirectAfterLogout) {
      if (here != "/login") return "/login";
      notifier.redirectAfterLogout = false;
    }

    final oldId = here == "/map"
        ? state.uri.queryParameters["candleId"]
        : here.startsWith("/map/candle/")
        ? here.split("/").last
        : null;
    if (oldId != null) return "/candles/$oldId";

    // Public candle links can be read without signing in. The normal entry
    // point still requires a session before presenting creation controls.
    const guestAllowed = {"/login", "/map", "/privacy", "/settings"};
    final from = state.uri.queryParameters["from"];
    final destination =
        from != null &&
            from.startsWith("/") &&
            !from.startsWith("//") &&
            !from.startsWith("/login") &&
            !from.startsWith("/splash")
        ? from
        : "/";
    final resume = Uri(
      path: "/splash",
      queryParameters: {"from": here == "/login" ? destination : state.uri.toString()},
    ).toString();

    return sessionAsync.when(
      loading: () => here == "/splash" ? null : resume,
      error: (_, _) => here == "/login"
          ? null
          : Uri(
              path: "/login",
              // Keep direct links too, not only destinations carried by splash.
              queryParameters: {"from": here == "/splash" ? destination : state.uri.toString()},
            ).toString(),
      data: (session) => switch (session) {
        SessionGuest() =>
          here == "/splash"
              ? destination
              : guestAllowed.contains(here) || here.startsWith("/candles/")
              ? null
              : Uri(path: "/login", queryParameters: {"from": state.uri.toString()}).toString(),
        SessionAuth() => (here == "/login" || here == "/splash") ? destination : null,
      },
    );
  }

  return GoRouter(
    initialLocation: "/splash",
    refreshListenable: notifier,
    redirect: redirect,
    routes: [
      GoRoute(
        path: "/login",
        name: "login",
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: "/splash",
        name: "splash",
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: "/delete-account",
        redirect: (_, _) => "/profile",
      ),
      GoRoute(
        path: "/privacy",
        name: "privacy",
        builder: (_, _) => const PrivacyPolicyScreen(),
      ),
      // The drawer lives in the outermost shell, above the navigator these pages
      // are pushed onto, so opening one never covers it.
      ShellRoute(
        builder: (context, state, child) => DrawerShell(child: child),
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppShell(child: child),
            routes: [
              GoRoute(
                path: "/",
                name: "candle",
                pageBuilder: (_, _) =>
                    const NoTransitionPage(key: ValueKey("gallery"), child: CandleGalleryScreen()),
              ),
              GoRoute(
                path: "/candles/:id",
                name: "candle_by_id",
                pageBuilder: (context, state) {
                  final id = int.tryParse(state.pathParameters["id"] ?? "");
                  return NoTransitionPage(
                    key: const ValueKey("gallery"),
                    child: id != null && id > 0
                        ? CandleGalleryScreen(candleId: id)
                        : Center(child: Text(context.l10n.invalidCandleLink)),
                  );
                },
              ),
            ],
          ),
          ShellRoute(
            builder: (context, state, child) {
              final title = switch (state.topRoute?.name) {
                "settings" => context.l10n.settings,
                "profile" => context.l10n.profile,
                "map" => context.l10n.map,
                "candle" => context.l10n.candle,
                _ => "",
              };

              return PageShell(title: title, child: child);
            },
            routes: [
              GoRoute(
                path: "/map",
                name: "map",
                builder: (_, _) => const MapScreen(),
                redirect: (_, state) {
                  final legacyId = state.uri.queryParameters["candleId"];
                  return legacyId == null ? null : "/candles/$legacyId";
                },
                routes: [
                  GoRoute(
                    path: "candle/:id",
                    redirect: (_, state) => "/candles/${state.pathParameters["id"]}",
                  ),
                ],
              ),
              GoRoute(
                path: "/settings",
                name: "settings",
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: "/profile",
                name: "profile",
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
