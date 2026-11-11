import "package:shared_preferences/shared_preferences.dart";
import "../domain/language_preferences.dart";

class LocalLanguagePreferences implements LanguagePreferences {
  LocalLanguagePreferences(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const _key = "languageCode";

  @override
  Future<String?> read() => _preferences.getString(_key);

  @override
  Future<void> save(String? languageCode) =>
      languageCode == null ? _preferences.remove(_key) : _preferences.setString(_key, languageCode);
}
