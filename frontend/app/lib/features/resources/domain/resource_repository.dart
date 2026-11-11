import "dart:typed_data";
import "media_resource.dart";
import "upload_cancellation.dart";

abstract interface class ResourceRepository {
  /// Throws [UploadCancelled] when [cancellation] fires and [UploadStalled]
  /// when the transfer stops making progress.
  Future<MediaResource> uploadImage(
    Uint8List bytes, {
    required void Function(double) onProgress,
    required UploadCancellation cancellation,
  });
}
