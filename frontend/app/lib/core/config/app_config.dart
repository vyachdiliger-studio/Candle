class AppConfig {
  static const telegramClientId = "8745967336";
  static const telegramAndroidAppUrl = "https://app176182968-login.tg.dev";
  static const telegramIosAppUrl = "";

  /// Backend API. Production by default; override for local development:
  ///   flutter run --dart-define=API_BASE_URL=http://localhost:8080/api
  /// (Android emulator: http://10.0.2.2:8080/api)
  static const String apiBaseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "https://candle.vyachdiliger.com/api",
  );

  /// Where a shared candle link points; the web build answers it for anyone
  /// without the app installed.
  static const String shareBaseUrl = String.fromEnvironment(
    "SHARE_BASE_URL",
    defaultValue: "https://candle.vyachdiliger.com",
  );

  static const String photonBaseUrl = "https://photon.komoot.io";
  static const String googleWebClientId =
      "663018526652-36cov1evmf91lj14ai4mckvrveb2h9k2.apps.googleusercontent.com";
}
