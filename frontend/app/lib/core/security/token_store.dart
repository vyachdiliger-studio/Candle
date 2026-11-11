import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "tokens.dart";

class TokenStore {
  final FlutterSecureStorage _storage;

  TokenStore(this._storage);

  static const _kAccess = "access_token";
  static const _kRefresh = "refresh_token";

  Future<void> _pending = Future.value();

  // Serialize reads/writes so access and refresh cannot come from two accounts.
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _write(Tokens tokens) async {
    await _storage.write(key: _kAccess, value: tokens.access);
    await _storage.write(key: _kRefresh, value: tokens.refresh);
  }

  Future<void> save(Tokens tokens) => _serial(() => _write(tokens));

  Future<bool> saveIfCurrent(Tokens tokens, bool Function() isCurrent) => _serial(() async {
    if (!isCurrent()) return false;
    await _write(tokens);
    return isCurrent();
  });

  Future<Tokens?> read() => _serial(() async {
    final access = await _storage.read(key: _kAccess) ?? "";
    final refresh = await _storage.read(key: _kRefresh) ?? "";
    return access.isEmpty || refresh.isEmpty ? null : Tokens(access: access, refresh: refresh);
  });

  Future<void> clear() => _serial(() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  });
}

final secureStorageProvider = Provider((_) => const FlutterSecureStorage());
final tokenStoreProvider = Provider(
  (ref) => TokenStore(ref.read(secureStorageProvider)),
);
