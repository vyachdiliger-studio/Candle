import "dart:async";

import "package:candle_frontend/features/settings/application/app_build_info_provider.dart";
import "package:candle_frontend/features/settings/application/language_controller.dart";
import "package:candle_frontend/features/settings/domain/app_build_info.dart";
import "package:candle_frontend/features/settings/presentation/app_info_tile.dart";
import "package:candle_frontend/features/settings/presentation/settings_screen.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:package_info_plus/package_info_plus.dart";

const revision = "1234567890abcdef1234567890abcdef12345678";
const build = AppBuildInfo(version: "1.2.3", buildNumber: "42", revision: revision);

void main() {
  test("reads the installed version and build rather than hardcoded release values", () async {
    PackageInfo.setMockInitialValues(
      appName: "Candle",
      packageName: "com.vyachdiliger.candle",
      version: "2.3.4",
      buildNumber: "73",
      buildSignature: "",
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final actual = await container.read(appBuildInfoProvider.future);
    expect(actual.version, "2.3.4");
    expect(actual.buildNumber, "73");
  });

  test("revision is optional and never invents a commit for local builds", () {
    expect(const AppBuildInfo(version: "1", buildNumber: "2").shortRevision, isNull);
    expect(const AppBuildInfo(version: "1", buildNumber: "2", revision: " ").shortRevision, isNull);
    expect(build.shortRevision, "1234567");
    expect(
      const AppBuildInfo(version: "1", buildNumber: "2", revision: "abc").shortRevision,
      "abc",
    );
  });

  test("web identity is compiled in and cannot change with a live version.json", () {
    PackageInfo.setMockInitialValues(
      appName: "Candle",
      packageName: "com.vyachdiliger.candle",
      version: "999.0.0",
      buildNumber: "999",
      buildSignature: "",
    );
    expect(bundledWebBuildInfo.version, const String.fromEnvironment("APP_VERSION"));
    expect(bundledWebBuildInfo.buildNumber, const String.fromEnvironment("APP_BUILD_NUMBER"));
    expect(bundledWebBuildInfo.revision, const String.fromEnvironment("BUILD_COMMIT"));
    expect(bundledWebBuildInfo.buildNumber, isNot("999"));
  });

  Future<void> pump(
    WidgetTester tester,
    ProviderContainer container, {
    String language = "en",
    double scale = 1,
    Widget child = const SettingsScreen(),
  }) => tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(body: child),
      ),
    ),
  );

  testWidgets("settings opens offline release notes and copies the full build identity", (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == "Clipboard.setData") copied = (call.arguments as Map)["text"] as String;
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final container = ProviderContainer(
      overrides: [appBuildInfoProvider.overrideWith((ref) async => build)],
    );
    addTearDown(container.dispose);
    await pump(tester, container);
    await tester.pumpAndSettle();
    expect(find.text("Version 1.2.3 · Build 42"), findsOneWidget);
    await tester.tap(find.text("About Candle"));
    await tester.pumpAndSettle();
    expect(find.text("Commit 1234567"), findsOneWidget);
    expect(find.text("What’s new"), findsOneWidget);
    expect(find.text("Comments on candles"), findsOneWidget);
    expect(find.text("Ukrainian and Thai"), findsOneWidget);
    await tester.tap(find.text("Copy build information"));
    await tester.pumpAndSettle();
    expect(copied, "Candle\nVersion 1.2.3 · Build 42\nCommit $revision");
    await tester.tap(find.text("Close"));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("Russian release notes fit a narrow phone with large text", (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        initialLanguageProvider.overrideWithValue("ru"),
        appBuildInfoProvider.overrideWith((ref) async => build),
      ],
    );
    addTearDown(container.dispose);
    await pump(tester, container, language: "ru", scale: 2, child: const AppInfoTile());
    await tester.pumpAndSettle();
    await tester.tap(find.text("О приложении Candle"));
    await tester.pumpAndSettle();
    expect(find.text("Версия 1.2.3 · Сборка 42"), findsWidgets);
    await tester.scrollUntilVisible(
      find.text("Украинский и тайский"),
      200,
      scrollable: find
          .descendant(of: find.byType(AlertDialog), matching: find.byType(Scrollable))
          .first,
    );
    expect(find.text("Украинский и тайский"), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text("Закрыть"));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets("metadata failure does not hide release notes and can be retried", (tester) async {
    var attempts = 0;
    final container = ProviderContainer(
      overrides: [
        appBuildInfoProvider.overrideWith((ref) async {
          if (attempts++ == 0) throw StateError("platform unavailable");
          return const AppBuildInfo(version: "1.0.0", buildNumber: "4");
        }),
      ],
    );
    addTearDown(container.dispose);
    await pump(tester, container, child: const AppInfoTile());
    await tester.pumpAndSettle();
    await tester.tap(find.text("About Candle"));
    await tester.pumpAndSettle();
    expect(find.text("What’s new"), findsOneWidget);
    expect(find.text("Copy build information"), findsNothing);
    await tester.tap(find.text("Retry"));
    await tester.pumpAndSettle();
    expect(find.text("Version 1.0.0 · Build 4"), findsWidgets);
    expect(find.text("Source revision not provided for this build"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("pending metadata still allows reading the bundled changelog", (tester) async {
    final container = ProviderContainer(
      overrides: [
        appBuildInfoProvider.overrideWith((ref) => Completer<AppBuildInfo>().future),
      ],
    );
    addTearDown(container.dispose);
    await pump(tester, container, child: const AppInfoTile());
    await tester.pump();
    await tester.tap(find.text("About Candle"));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text("What’s new"), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text("Copy build information"), findsNothing);
    await tester.tap(find.text("Close"));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AlertDialog), findsNothing);
  });
}
