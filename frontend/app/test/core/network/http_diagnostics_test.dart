import "dart:convert";
import "dart:typed_data";
import "package:candle_frontend/core/network/http_diagnostics.dart";
import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";

class Adapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) respond;
  Adapter(this.respond);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) => respond(options);
  @override
  void close({bool force = false}) {}
}

void main() {
  test("correlates logs, masks credentials and preserves wire payloads", () async {
    final lines = <String>[];
    final dio = Dio(BaseOptions(baseUrl: "https://example.test"));
    addTearDown(dio.close);
    dio.interceptors.add(HttpDiagnostics(enabled: true, output: lines.add));
    String? id;
    dio.httpClientAdapter = Adapter((options) async {
      id = options.headers["X-Request-ID"] as String;
      expect(options.data["idToken"], "google-secret");
      expect(options.queryParameters["refresh_token"], "query-secret");
      return ResponseBody.fromString(
        jsonEncode({"access": "access-secret", "refresh": "refresh-secret", "userId": 42}),
        200,
        headers: {
          Headers.contentTypeHeader: ["application/json"],
          "set-cookie": ["cookie-secret"],
        },
      );
    });
    final response = await dio.post(
      "/auth/google",
      data: {
        "idToken": "google-secret",
        "initData": "telegram-secret",
        "ids": [1, 2],
      },
      queryParameters: {"refresh_token": "query-secret"},
      options: Options(headers: {"Authorization": "Bearer header-secret"}),
    );
    expect(response.data["access"], "access-secret");
    final log = lines.join("\n");
    for (final secret in [
      "google-secret",
      "telegram-secret",
      "query-secret",
      "access-secret",
      "refresh-secret",
      "cookie-secret",
      "header-secret",
    ]) {
      expect(log, isNot(contains(secret)));
    }
    expect(log, contains("POST https://example.test/auth/google"));
    expect(log, contains('"ids":[1,2]'));
    expect(log, contains("<-- 200"));
    expect(lines.every((line) => line.startsWith("[HTTP $id]")), isTrue);
  });
  test("logs connection timeout without leaking exception details", () async {
    final lines = <String>[];
    final dio = Dio();
    addTearDown(dio.close);
    dio.interceptors.add(HttpDiagnostics(enabled: true, output: lines.add));
    dio.httpClientAdapter = Adapter(
      (options) async => throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
        message: "unsafe-token-detail",
      ),
    );
    await expectLater(dio.get("https://example.test/candles"), throwsA(isA<DioException>()));
    expect(lines.join(), contains("connectionTimeout status=NO_HTTP_RESPONSE"));
    expect(lines.join(), isNot(contains("unsafe-token-detail")));
  });
  test("logs HTTP failures and redacts their bodies", () async {
    final lines = <String>[];
    final dio = Dio();
    addTearDown(dio.close);
    dio.interceptors.add(HttpDiagnostics(enabled: true, output: lines.add));
    dio.httpClientAdapter = Adapter(
      (options) async => ResponseBody.fromString(
        '{"error":"unauthorized","token":"hidden"}',
        401,
        headers: {
          Headers.contentTypeHeader: ["application/json"],
        },
      ),
    );
    await expectLater(dio.get("https://example.test/candles"), throwsA(isA<DioException>()));
    expect(lines.join(), contains("status=401"));
    expect(lines.join(), contains("unauthorized"));
    expect(lines.join(), isNot(contains("hidden")));
  });
  test("disabled logger neither writes nor changes headers", () async {
    final dio = Dio();
    addTearDown(dio.close);
    dio.interceptors.add(HttpDiagnostics(enabled: false, output: (_) => fail("unexpected log")));
    dio.httpClientAdapter = Adapter((options) async {
      expect(options.headers.containsKey("X-Request-ID"), isFalse);
      return ResponseBody.fromString("{}", 200);
    });
    await dio.get("https://example.test/");
  });
}
