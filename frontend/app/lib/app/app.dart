import "../core/location/location_controller.dart";
import "package:candle_frontend/l10n/generated/app_localizations.dart";
import "package:candle_frontend/features/settings/application/language_controller.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "router.dart";

class App extends ConsumerWidget {
  const App({super.key});

  static const _bg = AppColors.surface;
  static const _accent = AppColors.primary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(locationInitializationProvider);
    final router = ref.watch(routerProvider);
    final language = ref.watch(languageControllerProvider);
    final locale = AppLocalizations.supportedLocales
        .where((locale) => locale.toLanguageTag() == language)
        .firstOrNull;

    final scheme = const ColorScheme.dark(
      primary: _accent,
      secondary: _accent,
      surface: _bg,
      onPrimary: AppColors.onPrimary,
      onSecondary: AppColors.onPrimary,
      onSurface: _accent,
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "Candle",
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: _bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.transparent,
          elevation: AppEffects.elevationNone,
          foregroundColor: _accent,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: _accent,
        ),
      ),
      routerConfig: router,
    );
  }
}
