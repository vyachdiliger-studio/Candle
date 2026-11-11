import "dart:convert";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";

/// One request ID per wire attempt, including token-refresh retries.
class HttpDiagnostics extends Interceptor {
  static const enabledByDefault = bool.fromEnvironment("HTTP_LOGGING", defaultValue: kDebugMode);
  static int _sequence = 0;
  static const _clockKey = "httpDiagnostics.clock";
  static const _idKey = "httpDiagnostics.id";
  final bool enabled;
  final void Function(String) output;

  HttpDiagnostics({this.enabled = enabledByDefault, void Function(String)? output})
    : output = output ?? ((line) => debugPrint(line));

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      final id = "app-${DateTime.now().microsecondsSinceEpoch}-${++_sequence}";
      options.headers["X-Request-ID"] = id;
      options.extra[_idKey] = id;
      options.extra[_clockKey] = Stopwatch()..start();
      final uri = options.uri.replace(
        userInfo: "",
        queryParameters: options.uri.queryParametersAll.isEmpty
            ? null
            : {
                for (final entry in options.uri.queryParametersAll.entries)
                  entry.key: sensitive(entry.key) ? ["[REDACTED]"] : entry.value,
              },
      );
      _write(id, "--> ${options.method} $uri");
      _write(id, "request headers: ${format(options.headers)}");
      _write(id, "request body: ${format(options.data)}");
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (enabled) {
      final id = response.requestOptions.extra[_idKey] as String? ?? "?";
      _write(id, "<-- ${response.statusCode} ${_elapsed(response.requestOptions)}ms");
      _write(id, "response headers: ${format(response.headers.map)}");
      _write(id, "response body: ${format(response.data)}");
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      final id = err.requestOptions.extra[_idKey] as String? ?? "?";
      _write(
        id,
        '<!! ${err.type.name} status=${err.response?.statusCode ?? "NO_HTTP_RESPONSE"} '
        '${_elapsed(err.requestOptions)}ms cause=${err.error?.runtimeType ?? "none"}',
      );
      if (err.response case final response?) {
        _write(id, "response headers: ${format(response.headers.map)}");
        _write(id, "response body: ${format(response.data)}");
      }
    }
    handler.next(err);
  }

  int _elapsed(RequestOptions options) =>
      (options.extra[_clockKey] as Stopwatch?)?.elapsedMilliseconds ?? 0;

  void _write(String id, String text) {
    final bounded = text.length > 16384 ? "${text.substring(0, 16384)} [TRUNCATED]" : text;
    // Short lines survive Android logcat's per-entry size limit.
    for (var offset = 0; offset < bounded.length; offset += 800) {
      final end = (offset + 800).clamp(0, bounded.length);
      output('[HTTP $id] ${offset == 0 ? "" : "... "}${bounded.substring(offset, end)}');
    }
  }

  static bool sensitive(String name) {
    final key = name.toLowerCase().replaceAll(RegExp("[^a-z0-9]"), "");
    return key.contains("token") ||
        key.contains("password") ||
        key.contains("secret") ||
        key.contains("credential") ||
        key.contains("cookie") ||
        key.contains("authorization") ||
        key.contains("apikey") ||
        const {"access", "refresh", "code", "assertion", "clientsecret", "initdata"}.contains(key);
  }

  static Object? redact(Object? value) {
    if (value is Uint8List) return "[binary body: ${value.length} bytes]";
    if (value is Map) {
      return {
        for (final entry in value.entries)
          "${entry.key}": sensitive("${entry.key}") ? "[REDACTED]" : redact(entry.value),
      };
    }
    if (value is Iterable) return value.map(redact).toList();
    if (value is String || value is num || value is bool || value == null) return value;
    return "[${value.runtimeType} body omitted]";
  }

  static String format(Object? value) {
    if (value is String) {
      try {
        return jsonEncode(redact(jsonDecode(value)));
      } catch (_) {
        return "[non-JSON text: ${value.length} chars]";
      }
    }
    return jsonEncode(redact(value));
  }
}
