import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../security/token_store.dart";
import "../security/token_refresher.dart";
import "../security/session_epoch.dart";
import "../config/app_config.dart";
import "http_diagnostics.dart";

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  final store = ref.read(tokenStoreProvider);
  final refresher = ref.read(tokenRefresherProvider);
  final scope = ref.read(sessionEpochProvider.notifier);
  const epochKey = "auth.sessionEpoch";
  Future<void>? refreshing;
  int? refreshingEpoch;

  bool current(RequestOptions options) => options.extra[epochKey] == scope.current;
  DioException cancelled(RequestOptions options) => DioException(
    requestOptions: options,
    type: DioExceptionType.cancel,
    error: const SessionChanged(),
  );

  Future<void> refreshFor(RequestOptions options) async {
    if (!current(options)) throw const SessionChanged();
    final tokens = await store.read();
    if (!current(options) || tokens == null) throw const SessionChanged();
    // A concurrent request may have already refreshed this session.
    if (options.headers["Authorization"] != "Bearer ${tokens.access}") return;
    final epoch = scope.current;
    if (refreshing != null && refreshingEpoch == epoch) return refreshing;
    final work = () async {
      final next = await refresher.refresh(tokens.refresh);
      if (!await store.saveIfCurrent(next, () => scope.current == epoch)) {
        throw const SessionChanged();
      }
    }();
    refreshing = work;
    refreshingEpoch = epoch;
    try {
      await work;
    } finally {
      if (identical(refreshing, work)) {
        refreshing = null;
        refreshingEpoch = null;
      }
    }
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.extra.putIfAbsent(epochKey, () => scope.current);
        if (!current(options)) return handler.reject(cancelled(options));
        try {
          final tokens = await store.read();
          if (!current(options)) return handler.reject(cancelled(options));
          options.headers.remove("Authorization");
          if (tokens != null) options.headers["Authorization"] = "Bearer ${tokens.access}";
          handler.next(options);
        } catch (error) {
          handler.reject(DioException(requestOptions: options, error: error));
        }
      },
      onResponse: (response, handler) {
        if (!current(response.requestOptions)) {
          return handler.reject(cancelled(response.requestOptions));
        }
        handler.next(response);
      },
    ),
  );
  dio.interceptors.add(HttpDiagnostics());
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) async {
        final options = error.requestOptions;
        if (!current(options)) return handler.reject(cancelled(options));
        if (error.response?.statusCode == 401 && options.extra["retried"] != true) {
          try {
            await refreshFor(options);
            if (!current(options)) return handler.reject(cancelled(options));
            options.extra["retried"] = true;
            return handler.resolve(await dio.fetch(options));
          } catch (_) {
            return handler.reject(current(options) ? error : cancelled(options));
          }
        }
        handler.next(error);
      },
    ),
  );
  return dio;
});
