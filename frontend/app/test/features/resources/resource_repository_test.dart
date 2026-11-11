import "dart:async";
import "dart:convert";
import "dart:typed_data";
import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:candle_frontend/features/resources/data/dio_resource_repository.dart";
import "package:candle_frontend/features/resources/domain/upload_cancellation.dart";
import "package:candle_frontend/features/candle/data/models/candle_dto.dart";

class Adapter implements HttpClientAdapter {
  Adapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions, Stream<Uint8List>?) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => respond(options, requestStream);
  @override
  void close({bool force = false}) {}
}

Dio _api() {
  final api = Dio(BaseOptions(baseUrl: "https://api.example"));
  api.httpClientAdapter = Adapter((options, _) async {
    return ResponseBody.fromString(
      jsonEncode({"id": "resource", "uploadUrl": "https://s3.example/key"}),
      200,
      headers: {
        "content-type": ["application/json"],
      },
    );
  });
  return api;
}

Dio _hangingUploads() {
  final uploads = Dio();
  uploads.httpClientAdapter = HangingAdapter();
  return uploads;
}

class HangingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    final never = Completer<ResponseBody>();
    cancelFuture?.then(
      (_) => never.completeError(
        DioException.requestCancelled(requestOptions: options, reason: "cancelled"),
      ),
    );
    return never.future;
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test("a transfer that stops making progress fails as stalled", () async {
    final repository = DioResourceRepository(
      _api(),
      _hangingUploads(),
      stallTimeout: const Duration(milliseconds: 50),
    );
    await expectLater(
      repository.uploadImage(
        Uint8List.fromList([1]),
        onProgress: (_) {},
        cancellation: UploadCancellation(),
      ),
      throwsA(isA<UploadStalled>()),
    );
  });

  test("cancelling an upload in flight fails as cancelled, not stalled", () async {
    final cancellation = UploadCancellation();
    final repository = DioResourceRepository(_api(), _hangingUploads());
    final result = repository.uploadImage(
      Uint8List.fromList([1]),
      onProgress: (_) {},
      cancellation: cancellation,
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    cancellation.cancel();
    await expectLater(result, throwsA(isA<UploadCancelled>()));
  });

  test(
    "resource upload uses raw bytes without Candle credentials and completes afterwards",
    () async {
      final requests = <String>[];
      final api = Dio(
        BaseOptions(baseUrl: "https://api.example", headers: {"Authorization": "Bearer candle"}),
      );
      final uploads = Dio();
      api.httpClientAdapter = Adapter((options, _) async {
        requests.add(options.path);
        final data = options.path == "/resources"
            ? {"id": "resource", "uploadUrl": "https://s3.example/bucket/key?signature=test"}
            : {
                "id": "resource",
                "url": "/resources/resource/content",
                "thumbnailUrl": "/resources/resource/thumbnail",
                "width": 100,
                "height": 200,
              };
        return ResponseBody.fromString(
          jsonEncode(data),
          200,
          headers: {
            "content-type": ["application/json"],
          },
        );
      });
      uploads.httpClientAdapter = Adapter((options, stream) async {
        requests.add("upload");
        expect(options.headers.containsKey("Authorization"), isFalse);
        expect(options.method, "PUT");
        expect(await stream!.expand((bytes) => bytes).toList(), [1, 2, 3]);
        return ResponseBody.fromString("", 200);
      });
      final resource =
          await DioResourceRepository(
            api,
            uploads,
          ).uploadImage(
            Uint8List.fromList([1, 2, 3]),
            onProgress: (_) {},
            cancellation: UploadCancellation(),
          );
      expect(requests, ["/resources", "upload", "/resources/resource/complete"]);
      expect(resource.id, "resource");
      expect(resource.thumbnailUrl, endsWith("/thumbnail"));
    },
  );

  test("candle persistence round trip retains background and old candles remain valid", () {
    final json = <String, dynamic>{
      "id": 1,
      "createdAt": "2026-09-01T00:00:00Z",
      "ignitedAt": "2026-09-01T00:00:00Z",
      "extinguishedAt": "2026-09-01T01:00:00Z",
      "location": null,
    };
    expect(CandleDto.fromJson(json).toDomain().background, isNull);
    json["background"] = {
      "id": "r",
      "url": "/resources/r/content",
      "thumbnailUrl": "/resources/r/thumbnail",
      "width": 100,
      "height": 200,
    };
    final candle = CandleDto.fromJson(json).toDomain();
    expect(
      CandleDto.fromJson(CandleDto.fromDomain(candle).toJson()).toDomain().background!.id,
      "r",
    );
  });
}
