import "features/settings/application/language_controller.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_web_plugins/url_strategy.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:rive/rive.dart";

import "app/app.dart";
import "core/config/package_name_provider.dart";
import "core/security/token_refresher.dart";
import "core/security/tokens.dart";
import "features/auth/domain/auth_repository.dart";
import "features/auth/data/dio_auth_repository.dart";

Future<void> main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  await RiveNative.init();

  final info = await PackageInfo.fromPlatform();

  final preferencesContainer = ProviderContainer();
  String? language;
  try {
    language = await preferencesContainer.read(languagePreferencesProvider).read();
  } catch (_) {
    // Storage may be unavailable in private browsing; use the device language.
  } finally {
    preferencesContainer.dispose();
  }

  runApp(
    ProviderScope(
      overrides: [
        initialLanguageProvider.overrideWithValue(language),
        packageNameProvider.overrideWithValue(info.packageName),
        tokenRefresherProvider.overrideWith((ref) {
          return _AuthTokenRefresher(ref.read(authRepositoryProvider));
        }),
      ],
      child: const App(),
    ),
  );
}

class _AuthTokenRefresher implements TokenRefresher {
  final AuthRepository repository;

  _AuthTokenRefresher(this.repository);

  @override
  Future<Tokens> refresh(String refreshToken) async =>
      (await repository.refresh(refreshToken: refreshToken)).tokens;
}
