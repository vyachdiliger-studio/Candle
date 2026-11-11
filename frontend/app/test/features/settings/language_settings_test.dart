import "package:candle_frontend/features/auth/presentation/login_screen.dart";
import "dart:async";

import "package:candle_frontend/features/settings/application/language_controller.dart";
import "package:candle_frontend/features/settings/domain/language_preferences.dart";
import "package:candle_frontend/features/settings/presentation/settings_screen.dart";
import "package:candle_frontend/features/auth/presentation/widgets/password_login_form.dart";
import "package:candle_frontend/features/auth/application/login_controller.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";

class MemoryLanguagePreferences implements LanguagePreferences {
  String? value;
  final writes = <String?>[];
  Completer<void>? firstWrite;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> save(String? languageCode) async {
    writes.add(languageCode);
    if (writes.length == 1) await firstWrite?.future;
    value = languageCode;
  }
}

class LocalizedTestApp extends ConsumerWidget {
  const LocalizedTestApp({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(languageControllerProvider);
    return MaterialApp(
      locale: code == null ? null : Locale(code),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }
}

void main() {
  testWidgets("language switches immediately, persists and includes device default", (
    tester,
  ) async {
    final preferences = MemoryLanguagePreferences();
    final container = ProviderContainer(
      overrides: [
        languagePreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LocalizedTestApp(child: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Language"), findsOneWidget);
    await tester.tap(find.text("Русский"));
    await tester.pumpAndSettle();
    expect(find.text("Язык"), findsOneWidget);
    expect(preferences.value, "ru");
    await tester.tap(find.text("Язык устройства"));
    await tester.pumpAndSettle();
    expect(find.text("Language"), findsOneWidget);
    expect(preferences.value, isNull);
  });

  test("rapid choices are persisted in order", () async {
    final preferences = MemoryLanguagePreferences()..firstWrite = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        languagePreferencesProvider.overrideWithValue(preferences),
        initialLanguageProvider.overrideWithValue("en"),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(languageControllerProvider.notifier);
    final first = controller.select("ru");
    final second = controller.select("en");
    expect(container.read(languageControllerProvider), "en");
    await Future<void>.delayed(Duration.zero);
    expect(preferences.writes, ["ru"]);
    preferences.firstWrite!.complete();
    await Future.wait([first, second]);
    expect(preferences.value, "en");
  });

  testWidgets("switching language preserves form text and retranslates validation", (tester) async {
    final container = ProviderContainer(
      overrides: [
        languagePreferencesProvider.overrideWithValue(MemoryLanguagePreferences()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LocalizedTestApp(child: PasswordLoginForm()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, "myname");
    await tester.tap(find.text("Continue"));
    await tester.pump();
    expect(find.textContaining("Enter a username"), findsOneWidget);
    final controller = container.read(loginControllerProvider.notifier);
    await container.read(languageControllerProvider.notifier).select("ru");
    await tester.pumpAndSettle();
    expect(find.text("myname"), findsOneWidget);
    expect(find.textContaining("Введите имя пользователя"), findsOneWidget);
    expect(identical(controller, container.read(loginControllerProvider.notifier)), isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets("Russian login fits a narrow phone screen", (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialLanguageProvider.overrideWithValue("ru")],
        child: const LocalizedTestApp(child: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Добро пожаловать в Candle"), findsOneWidget);
    expect(find.text("Войти через Telegram"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
