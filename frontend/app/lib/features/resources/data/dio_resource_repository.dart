import "dart:async";
import "dart:typed_data";

import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "/core/network/dio_provider.dart";
import "../domain/media_resource.dart";
import "../domain/resource_repository.dart";
import "../domain/upload_cancellation.dart";
import "media_resource_dto.dart";

part "dio_resource_repository.g.dart";

@Riverpod(keepAlive: true)
ResourceRepository resourceRepository(Ref ref) {
  final uploads = Dio();
  ref.onDispose(() => uploads.close(force: true));
  return DioResourceRepository(ref.watch(dioProvider), uploads);
}

class DioResourceRepository implements ResourceRepository {
  const DioResourceRepository(
    this.api,
    this.uploads, {
    this.stallTimeout = const Duration(seconds: 30),
  });

  /// A slow upload is fine as long as bytes keep moving; only silence is fatal.
  final Duration stallTimeout;
  final Dio api;
  // Presigned S3 requests must not carry Candle credentials or API interceptors.
  // Dio's own send/receive timeouts cap the whole transfer, so the stall
  // watchdog below replaces them.
  final Dio uploads;

  @override
  Future<MediaResource> uploadImage(
    Uint8List bytes, {
    required void Function(double) onProgress,
    required UploadCancellation cancellation,
  }) async {
    final token = CancelToken();
    var stalled = false;
    Timer? watchdog;
    void restartWatchdog() {
      watchdog?.cancel();
      watchdog = Timer(stallTimeout, () {
        stalled = true;
        token.cancel();
      });
    }

    unawaited(cancellation.whenCancelled.then((_) => token.cancel()));
    try {
      final created = await api.post<Map<String, dynamic>>("/resources", cancelToken: token);
      final id = created.data!["id"] as String;
      final uploadUrl = created.data!["uploadUrl"] as String;
      restartWatchdog();
      await uploads.put<void>(
        uploadUrl,
        data: bytes,
        cancelToken: token,
        options: Options(contentType: "application/octet-stream"),
        onSendProgress: (sent, total) {
          restartWatchdog();
          if (total > 0) onProgress(sent / total);
        },
      );
      watchdog?.cancel();
      onProgress(1);
      final completed = await api.post<Map<String, dynamic>>(
        "/resources/$id/complete",
        cancelToken: token,
        options: Options(receiveTimeout: const Duration(minutes: 2)),
      );
      return MediaResourceDto(completed.data!).toDomain();
    } on DioException {
      if (token.isCancelled) throw stalled ? const UploadStalled() : const UploadCancelled();
      rethrow;
    } finally {
      watchdog?.cancel();
    }
  }
}
