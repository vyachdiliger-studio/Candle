import "package:candle_frontend/core/errors/app_failure.dart";
import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "/core/security/session_epoch.dart";
import "../../resources/data/image_selection.dart";
import "../../resources/data/dio_resource_repository.dart";
import "../../resources/domain/upload_cancellation.dart";
import "background_editor_state.dart";
import "candle_controller.dart";

part "background_editor_controller.g.dart";

@riverpod
class BackgroundEditorController extends _$BackgroundEditorController {
  UploadCancellation? _upload;

  @override
  BackgroundEditorState build(int? candleId) {
    ref.watch(sessionEpochProvider);
    ref.onDispose(() => _upload?.cancel());
    final candle = ref.read(candleControllerProvider(candleId)).value;
    return BackgroundEditorState(resource: candle?.candle?.background ?? candle?.draftBackground);
  }

  Future<void> pick() async {
    if (state.busy) return;
    final operationRef = ref;
    state = state.copyWith(operation: BackgroundOperation.picking, error: null);
    try {
      final bytes = await ref.read(imageSelectionProvider).pick();
      if (!operationRef.mounted) return;
      if (bytes != null) {
        state = state.copyWith(preview: bytes, resource: null, changed: true, saved: false);
      }
    } catch (error) {
      if (operationRef.mounted) state = state.copyWith(error: _message(error));
    } finally {
      if (operationRef.mounted) state = state.copyWith(operation: null);
    }
  }

  void remove() {
    if (!state.busy) {
      state = state.copyWith(
        resource: null,
        preview: null,
        changed: true,
        saved: false,
        error: null,
      );
    }
  }

  void cancelUpload() => _upload?.cancel();

  Future<void> save() async {
    if (state.busy || !state.changed) return;
    final operationRef = ref;
    final cancellation = _upload = UploadCancellation();
    state = state.copyWith(operation: BackgroundOperation.saving, error: null);
    try {
      if (state.preview != null && state.resource == null) {
        state = state.copyWith(operation: BackgroundOperation.uploading, progress: 0);
        final resource = await ref
            .read(resourceRepositoryProvider)
            .uploadImage(
              state.preview!,
              onProgress: (progress) {
                if (operationRef.mounted) state = state.copyWith(progress: progress);
              },
              cancellation: cancellation,
            );
        if (!operationRef.mounted) return;
        state = state.copyWith(resource: resource);
      }
      state = state.copyWith(operation: BackgroundOperation.saving);
      await ref.read(candleControllerProvider(candleId).notifier).setBackground(state.resource);
      if (operationRef.mounted) state = state.copyWith(saved: true, changed: false);
    } on UploadCancelled {
      // The user backed out; the picked image stays so they can retry.
    } catch (error) {
      if (operationRef.mounted) state = state.copyWith(error: _message(error));
    } finally {
      _upload = null;
      if (operationRef.mounted) state = state.copyWith(operation: null);
    }
  }

  AppFailure _message(Object error) {
    if (error is AppFailure) return error;
    if (error is UploadStalled) return AppFailure.uploadStalled;
    if (error is DioException) {
      return switch (error.response?.data) {
        "image_too_large" => AppFailure.imageTooLarge,
        "image_dimensions_too_large" => AppFailure.imageDimensionsTooLarge,
        "unsupported_image_format" || "invalid_image" => AppFailure.invalidImage,
        _ => AppFailure.uploadFailed,
      };
    }
    return AppFailure.imageOpenFailed;
  }
}
