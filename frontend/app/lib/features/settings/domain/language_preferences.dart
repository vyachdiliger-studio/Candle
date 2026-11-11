abstract interface class LanguagePreferences {
  Future<String?> read();
  Future<void> save(String? languageCode);
}
