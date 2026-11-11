import "dart:async";

class UploadCancellation {
  final _cancelled = Completer<void>();

  Future<void> get whenCancelled => _cancelled.future;

  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }
}

class UploadCancelled implements Exception {
  const UploadCancelled();
}

class UploadStalled implements Exception {
  const UploadStalled();
}
