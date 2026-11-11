import "dart:convert";

import "package:dart_scope_functions/dart_scope_functions.dart";

import "package:flutter_riverpod/experimental/persist.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

/// Riverpod's persistence over shared_preferences rather than the official
/// riverpod_sqflite, whose sqflite dependency ships for Android, iOS and macOS
/// only - the web would need a WASM build of sqlite alongside the app.
final class PreferencesStorage extends Storage<String, String> {
  final SharedPreferencesWithCache preferences;

  PreferencesStorage(this.preferences);

  static const _prefix = "persist.";

  @override
  Future<PersistedData<String>?> read(String key) async {
    final stored = preferences.getString("$_prefix$key");

    if (stored == null) return null;

    final json = jsonDecode(stored) as Map<String, dynamic>;

    return PersistedData(
      json["data"] as String,
      destroyKey: json["destroyKey"] as String?,
      expireAt: (json["expireAt"] as String?)?.let(DateTime.parse),
    );
  }

  @override
  Future<void> write(String key, String value, StorageOptions options) {
    final expireAt = options.cacheTime.duration?.let(
      DateTime.now().toUtc().add,
    );

    return preferences.setString(
      "$_prefix$key",
      jsonEncode({
        "data": value,
        "destroyKey": options.destroyKey,
        "expireAt": expireAt?.toIso8601String(),
      }),
    );
  }

  @override
  Future<void> delete(String key) => preferences.remove("$_prefix$key");

  @override
  void deleteOutOfDate() {
    final now = DateTime.now().toUtc();

    preferences.keys
        .where((it) => it.startsWith(_prefix))
        .where((it) => _isExpired(it, now))
        .forEach(preferences.remove);
  }

  bool _isExpired(String key, DateTime now) {
    final stored = preferences.getString(key);

    if (stored == null) return false;

    final expireAt = (jsonDecode(stored) as Map<String, dynamic>)["expireAt"] as String?;

    return expireAt != null && DateTime.parse(expireAt).isBefore(now);
  }
}

final storageProvider = FutureProvider<Storage<String, String>>((ref) async {
  final preferences = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );

  return PreferencesStorage(preferences);
});
