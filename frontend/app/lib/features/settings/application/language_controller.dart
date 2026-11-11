import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";
import "../data/local_language_preferences.dart";
import "../domain/language_preferences.dart";

final languagePreferencesProvider = Provider<LanguagePreferences>(
  (ref) => LocalLanguagePreferences(SharedPreferencesAsync()),
);

final initialLanguageProvider = Provider<String?>((ref) => null);

final languageControllerProvider = NotifierProvider<LanguageController, String?>(
  LanguageController.new,
);

class LanguageController extends Notifier<String?> {
  Future<void> _pendingSave = Future.value();

  @override
  String? build() => ref.read(initialLanguageProvider);

  Future<void> select(String? languageCode) {
    state = languageCode;
    final preferences = ref.read(languagePreferencesProvider);
    final save = _pendingSave.then((_) => preferences.save(languageCode));
    _pendingSave = save.catchError((Object _) {});
    return save;
  }
}
