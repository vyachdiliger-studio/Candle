import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";
import "../../../core/security/session_epoch.dart";

final galleryPreferencesProvider = Provider((ref) => SharedPreferencesAsync());
final galleryStorageProvider = Provider(
  (ref) =>
      GalleryStorage(ref.read(galleryPreferencesProvider), ref.read(sessionEpochProvider.notifier)),
);

class GalleryStorage {
  final SharedPreferencesAsync preferences;
  final SessionEpoch scope;
  Future<void> _pending = Future.value();
  GalleryStorage(this.preferences, this.scope);

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<List<String>?> history(int? userId) =>
      _serial(() => preferences.getStringList('candles.recent.${userId ?? "guest"}'));
  Future<int?> selection(int? userId) =>
      _serial(() => preferences.getInt('candles.selected.${userId ?? "guest"}'));

  Future<void> saveHistory(int? userId, int epoch, List<String> ids) => _serial(() async {
    if (scope.current != epoch) return;
    await preferences.setStringList('candles.recent.${userId ?? "guest"}', ids);
  });
  Future<void> select(int? userId, int epoch, int? id) => _serial(() async {
    if (scope.current != epoch) return;
    final key = 'candles.selected.${userId ?? "guest"}';
    if (id == null) {
      await preferences.remove(key);
    } else {
      await preferences.setInt(key, id);
    }
  });

  // Wait for earlier writes before removal; stale work cannot recreate history.
  // Also removes histories left by the older implementation for other accounts.
  Future<void> clearOnLogout() => _serial(() async {
    final keys = await preferences.getKeys();
    for (final key in keys.where(
      (key) =>
          key.startsWith("candles.recent.") ||
          key.startsWith("candles.selected.") ||
          key == "persist.user",
    )) {
      await preferences.remove(key);
    }
  });
}
