import "package:candle_frontend/l10n/generated/app_localizations.dart";
import "package:candle_frontend/core/security/tokens.dart";
import "package:candle_frontend/app/router.dart";
import "package:candle_frontend/features/auth/auth.dart";
import "package:candle_frontend/features/user/application/user_controller.dart";
import "package:candle_frontend/features/user/domain/models/user.dart";
import "dart:async";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:candle_frontend/features/candle/presentation/screens/candle_gallery_screen.dart";
import "package:candle_frontend/features/candle/presentation/screens/candle_screen.dart";
import "package:candle_frontend/features/candle/presentation/candle_rive_loader_provider.dart";
import "package:candle_frontend/features/candle/application/candle_controller.dart";
import "package:candle_frontend/features/candle/application/candle_gallery_controller.dart";
import "package:candle_frontend/features/candle/application/gallery_preferences.dart";
import "package:candle_frontend/features/candle/application/share_candle.dart";
import "package:candle_frontend/features/candle/data/dio_candle_repository.dart";
import "package:candle_frontend/features/candle/domain/models/candle.dart";
import "package:candle_frontend/features/candle/domain/remote_candle_repository.dart";
import "package:dartz/dartz.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

class MemoryPreferences implements SharedPreferencesAsync {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  final values = <String, Object>{};
  @override
  Future<Set<String>> getKeys({Set<String>? allowList}) async =>
      values.keys.where((key) => allowList == null || allowList.contains(key)).toSet();
  @override
  Future<List<String>?> getStringList(String key) async => values[key] as List<String>?;
  @override
  Future<int?> getInt(String key) async => values[key] as int?;
  @override
  Future<void> setStringList(String key, List<String> value) async {
    values[key] = value;
  }

  @override
  Future<void> setInt(String key, int value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

Candle candle(int id, {int author = 42, bool burning = true}) => Candle(
  id: id,
  createdAt: DateTime.utc(2026),
  ignitedAt: DateTime.utc(2026),
  extinguishedAt: burning ? DateTime.utc(2100) : DateTime.utc(2020),
  location: null,
  author: CandleAuthor(id: author, username: "author_$author"),
);

class Repository implements RemoteCandleRepository {
  final calls = <String?>[];
  final updates = <({int id, String message})>[];
  final candles = <int, Candle>{};
  bool failCreate = false;
  bool failUpdate = false;
  @override
  Future<Either<Unit, CandlePage>> search({
    int? authorId,
    List<int>? ids,
    String? status,
    String? cursor,
    int limit = 30,
  }) async {
    calls.add(cursor);
    final all = candles.values
        .where(
          (c) =>
              (authorId == null || c.author?.id == authorId) &&
              (ids == null || ids.contains(c.id)) &&
              (status != "burning" || c.extinguishedAt.isAfter(DateTime.now())),
        )
        .toList();
    if (ids != null) return right(CandlePage(all, null));
    final offset = int.parse(cursor ?? "0");
    return right(
      CandlePage(
        all.skip(offset).take(1).toList(),
        offset + 1 < all.length ? "${offset + 1}" : null,
      ),
    );
  }

  @override
  Future<Either<Unit, Candle>> getById(int id) async =>
      candles.containsKey(id) ? right(candles[id]!) : left(unit);
  @override
  Future<Either<Unit, Candle>> create({String? message, String? backgroundResourceId}) async {
    if (failCreate) return left(unit);
    final created = candle(100).copyWith(message: message);
    candles[100] = created;
    return right(created);
  }

  @override
  Future<Either<Unit, Candle>> update({required int id, required String message}) async {
    updates.add((id: id, message: message));
    if (failUpdate || !candles.containsKey(id)) return left(unit);
    final updated = candles[id]!.copyWith(message: message.trim().isEmpty ? null : message.trim());
    candles[id] = updated;
    return right(updated);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PendingSession extends SessionController {
  final Completer<SessionState> completion;
  PendingSession(this.completion);
  @override
  Future<SessionState> build() => completion.future;
  @override
  Future<void> logout() async {
    state = const AsyncData(SessionState.guest());
  }
}

class TestUser extends UserController {
  @override
  Future<User> build() async => User(id: 42, createdAt: DateTime.utc(2026), username: "test");
}

void main() {
  late Repository repository;
  late MemoryPreferences preferences;
  late ProviderContainer container;
  setUp(() {
    repository = Repository();
    preferences = MemoryPreferences();
    container = ProviderContainer(
      overrides: [
        galleryUserIdProvider.overrideWithValue(42),
        candleRepositoryProvider.overrideWithValue(repository),
        galleryPreferencesProvider.overrideWithValue(preferences),
      ],
    );
  });
  tearDown(() => container.dispose());

  test("loads every page of mine and restores recent in visit order", () async {
    repository.candles.addAll({
      1: candle(1),
      2: candle(2),
      3: candle(3, burning: false),
      4: candle(4, author: 7),
      5: candle(5, author: 7),
      6: candle(6, author: 7, burning: false),
    });
    preferences.values["candles.recent.42"] = ["5", "4", "6", "1"];
    final gallery = await container.read(candleGalleryProvider.future);
    expect(gallery.mine.map((c) => c.id), [1, 2]);
    expect(gallery.recent.map((c) => c.id), [5, 4]);
    expect(repository.calls, [null, "1", null]);
  });

  test("opening own extinguished candle keeps it in mine until new startup", () async {
    repository.candles[3] = candle(3, burning: false);
    await container.read(candleGalleryProvider.future);
    final controller = container.read(candleGalleryProvider.notifier);
    await controller.open(3);
    await controller.open(3);
    expect(container.read(candleGalleryProvider).value!.mine.map((c) => c.id), [3]);
    expect(container.read(candleGalleryProvider).value!.recent, isEmpty);
    expect(container.read(candleGalleryProvider).value!.selectedId, 3);
    container.invalidate(candleGalleryProvider);
    expect((await container.read(candleGalleryProvider.future)).mine, isEmpty);
  });

  test("opening recent twice selects it without reordering or duplicates", () async {
    repository.candles.addAll({4: candle(4, author: 7), 5: candle(5, author: 7)});
    await container.read(candleGalleryProvider.future);
    final controller = container.read(candleGalleryProvider.notifier);
    await controller.open(4);
    await controller.open(5);
    await controller.open(4);
    final gallery = container.read(candleGalleryProvider).value!;
    expect(gallery.recent.map((c) => c.id), [4, 5]);
    expect(gallery.selectedId, 4);
    expect(preferences.values["candles.recent.42"], ["4", "5"]);
  });

  test("closing a recent persists, keeps own candles and permits reopening", () async {
    repository.candles.addAll({1: candle(1), 4: candle(4, author: 7), 5: candle(5, author: 7)});
    await container.read(candleGalleryProvider.future);
    final controller = container.read(candleGalleryProvider.notifier);
    await controller.open(4);
    await controller.open(5);
    controller.closeRecent(1);
    expect(container.read(candleGalleryProvider).value!.mine.single.id, 1);
    controller.closeRecent(5);
    expect(container.read(candleGalleryProvider).value!.selectedId, 4);
    await controller.refreshQuietly();
    expect(container.read(candleGalleryProvider).value!.recent.map((c) => c.id), [4]);
    expect(preferences.values["candles.recent.42"], ["4"]);
    container.invalidate(candleGalleryProvider);
    expect((await container.read(candleGalleryProvider.future)).recent.map((c) => c.id), [4]);
    await container.read(candleGalleryProvider.notifier).open(5);
    expect(container.read(candleGalleryProvider).value!.recent.map((c) => c.id), [4, 5]);
  });

  test("creation selects new candle and clears draft only on success", () async {
    await container.read(candleGalleryProvider.future);
    await container.read(candleControllerProvider(null).future);
    final draft = container.read(candleControllerProvider(null).notifier);
    draft.messageUpdated("For family");
    repository.failCreate = true;
    await expectLater(draft.onTap(), throwsException);
    expect(container.read(candleControllerProvider(null)).value!.message, "For family");
    repository.failCreate = false;
    await draft.onTap();
    expect(container.read(candleGalleryProvider).value!.selectedId, 100);
    expect(container.read(candleGalleryProvider).value!.mine.single.message, "For family");
    expect(container.read(candleControllerProvider(null)).value!.message, "");
    expect(container.read(candleControllerProvider(null)).value!.candle, isNull);
  });

  testWidgets("close button removes only the recent and navigates to own candle", (tester) async {
    repository.candles.addAll({1: candle(1), 4: candle(4, author: 7)});
    final ui = ProviderContainer(
      overrides: [
        galleryUserIdProvider.overrideWithValue(42),
        candleRepositoryProvider.overrideWithValue(repository),
        galleryPreferencesProvider.overrideWithValue(preferences),
        candleRiveFileProvider.overrideWith((ref) => Completer<Never>().future),
      ],
    );
    await ui.read(candleGalleryProvider.future);
    await ui.read(candleGalleryProvider.notifier).open(4);
    final router = GoRouter(
      initialLocation: "/candles/4",
      routes: [
        GoRoute(
          path: "/",
          builder: (_, _) => const Scaffold(body: CandleGalleryScreen()),
        ),
        GoRoute(
          path: "/candles/:id",
          builder: (_, state) => Scaffold(
            body: CandleGalleryScreen(candleId: int.parse(state.pathParameters["id"]!)),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ui,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byTooltip("Remove from recent candles"), findsOneWidget);
    await tester.tap(find.byTooltip("Remove from recent candles"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(ui.read(candleGalleryProvider).value!.recent, isEmpty);
    expect(ui.read(candleGalleryProvider).value!.selectedId, 1);
    expect(router.routeInformationProvider.value.uri.path, "/candles/1");
    expect(find.byTooltip("Remove from recent candles"), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    ui.dispose();
  });

  testWidgets("draft message is single-line and explicit Light creates the candle", (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/",
          builder: (_, _) => const Scaffold(body: CandleScreen()),
        ),
        GoRoute(
          path: "/candles/:id",
          builder: (_, state) => Scaffold(
            body: CandleScreen(candleId: int.parse(state.pathParameters["id"]!)),
          ),
        ),
      ],
    );
    final ui = ProviderContainer(
      overrides: [
        galleryUserIdProvider.overrideWithValue(42),
        candleRepositoryProvider.overrideWithValue(repository),
        galleryPreferencesProvider.overrideWithValue(preferences),
        candleRiveFileProvider.overrideWith((ref) => Completer<Never>().future),
      ],
    );
    await ui.read(candleGalleryProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ui,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    final field = tester.widget<TextField>(find.byKey(const ValueKey("candle-draft-message")));
    expect(field.maxLines, 1);
    expect(field.textInputAction, TextInputAction.done);
    await tester.enterText(find.byKey(const ValueKey("candle-draft-message")), "For tomorrow");
    await tester.tap(find.byKey(const ValueKey("light-candle")));
    await tester.pumpAndSettle();

    expect(repository.candles[100]!.message, "For tomorrow");
    expect(router.routeInformationProvider.value.uri.path, "/candles/100");
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    ui.dispose();
  });

  testWidgets("owned candle uses explicit edit, cancel and save actions", (tester) async {
    repository.candles[1] = candle(1).copyWith(message: "Saved message");
    await container.read(candleGalleryProvider.future);
    await container.read(candleControllerProvider(1).future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CandleScreen(candleId: 1)),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey("candle-message-editor")), findsNothing);
    await tester.tap(find.byKey(const ValueKey("edit-candle-message")));
    await tester.pump();
    final editor = tester.widget<TextField>(find.byKey(const ValueKey("candle-message-editor")));
    expect(editor.maxLines, 1);

    await tester.enterText(find.byKey(const ValueKey("candle-message-editor")), "Discard me");
    await tester.tap(find.byKey(const ValueKey("cancel-candle-message")));
    await tester.pump();
    expect(repository.updates, isEmpty);
    expect(find.text("Saved message"), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey("edit-candle-message")));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey("candle-message-editor")), "New message");
    await tester.tap(find.byKey(const ValueKey("save-candle-message")));
    await tester.pump();

    expect(repository.updates, [(id: 1, message: "New message")]);
    expect(repository.candles[1]!.message, "New message");
    expect(find.text("New message"), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey("edit-candle-message")));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey("candle-message-editor")), "Saved with Done");
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(repository.updates.last, (id: 1, message: "Saved with Done"));
    expect(find.text("Saved with Done"), findsOneWidget);
  });

  testWidgets("swipe to draft and thumbnail back keep selection and URL in sync", (tester) async {
    repository.candles[1] = candle(1);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/",
          pageBuilder: (_, _) =>
              const NoTransitionPage(key: ValueKey("gallery"), child: CandleGalleryScreen()),
        ),
        GoRoute(
          path: "/candles/:id",
          pageBuilder: (_, state) => NoTransitionPage(
            key: const ValueKey("gallery"),
            child: CandleGalleryScreen(candleId: int.parse(state.pathParameters["id"]!)),
          ),
        ),
      ],
    );
    final uiContainer = ProviderContainer(
      overrides: [
        galleryUserIdProvider.overrideWithValue(42),
        candleRepositoryProvider.overrideWithValue(repository),
        galleryPreferencesProvider.overrideWithValue(preferences),
        candleRiveFileProvider.overrideWith((ref) => Completer<Never>().future),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: uiContainer,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          routerConfig: router,
          builder: (_, child) => Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(uiContainer.read(candleGalleryProvider).value!.selectedId, 1);
    await tester.drag(find.byType(PageView), const Offset(650, 0));
    await tester.pumpAndSettle();
    expect(uiContainer.read(candleGalleryProvider).value!.selectedId, isNull);
    await tester.enterText(find.byType(TextField), "Draft survives swipes");
    await tester.tap(find.text("Candle #1"));
    await tester.pumpAndSettle();
    expect(uiContainer.read(candleGalleryProvider).value!.selectedId, 1);
    expect(router.routeInformationProvider.value.uri.path, "/candles/1");
    await tester.tap(find.text("New candle"));
    await tester.pumpAndSettle();
    expect(find.text("Draft survives swipes"), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    uiContainer.dispose();
    router.dispose();
  });

  testWidgets("legacy shared link survives session loading and opens for a guest", (tester) async {
    repository.candles[5] = candle(5, author: 7);
    final session = Completer<SessionState>();
    final ui = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(() => PendingSession(session)),
        userControllerProvider.overrideWith(TestUser.new),
        candleRepositoryProvider.overrideWithValue(repository),
        galleryPreferencesProvider.overrideWithValue(preferences),
        candleRiveFileProvider.overrideWith((ref) => Completer<Never>().future),
      ],
    );
    final router = ui.read(routerProvider);
    router.go("/map?candleId=5");
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ui,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    expect(router.routeInformationProvider.value.uri.path, "/splash");
    session.complete(const SessionState.guest());
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, "/candles/5");
    expect(ui.read(candleGalleryProvider).value!.selectedId, 5);
    expect(ui.read(candleGalleryProvider).value!.recent.single.id, 5);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    ui.dispose();
  });

  testWidgets("normal guest startup opens login before creation", (tester) async {
    final session = Completer<SessionState>();
    final ui = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(() => PendingSession(session)),
      ],
    );
    final router = ui.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ui,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    expect(router.routeInformationProvider.value.uri.path, "/splash");
    expect(find.byType(CandleGalleryScreen), findsNothing);
    session.complete(const SessionState.guest());
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, "/login");
    expect(find.byType(CandleGalleryScreen), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    ui.dispose();
  });

  testWidgets("logout from a pushed profile goes straight to login and clears stack", (
    tester,
  ) async {
    repository.candles[1] = candle(1);
    final session = Completer<SessionState>()
      ..complete(const SessionState.auth(Tokens(access: "test", refresh: "test"), 42));
    final ui = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(() => PendingSession(session)),
        userControllerProvider.overrideWith(TestUser.new),
        candleRepositoryProvider.overrideWithValue(repository),
        galleryPreferencesProvider.overrideWithValue(preferences),
        candleRiveFileProvider.overrideWith((ref) => Completer<Never>().future),
      ],
    );
    final router = ui.read(routerProvider);
    router.go("/candles/1");
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ui,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.pushNamed("profile");
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text("Logout"),
      200,
      scrollable: find
          .descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable))
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("Logout"));
    expect(ui.read(sessionControllerProvider).value, isA<SessionGuest>());
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, "/login");
    expect(find.byType(CandleGalleryScreen), findsNothing);
    expect(router.canPop(), isFalse);
    // Explicitly opening a shared link after logout must still be possible.
    router.go("/candles/1");
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, "/candles/1");
    expect(ui.read(sessionControllerProvider).value, isA<SessionGuest>());
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    ui.dispose();
  });

  test("share uses canonical gallery URL without map query", () {
    final link = candleShareLink(candle(137610));
    expect(link.path, "/candles/137610");
    expect(link.queryParameters, isEmpty);
  });
}
