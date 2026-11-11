import "package:candle_frontend/core/errors/app_failure.dart";
import "dart:typed_data";
import "package:freezed_annotation/freezed_annotation.dart";
import "../../resources/domain/media_resource.dart";

part "background_editor_state.freezed.dart";

enum BackgroundOperation { picking, uploading, saving }

@freezed
abstract class BackgroundEditorState with _$BackgroundEditorState {
  const BackgroundEditorState._();
  const factory BackgroundEditorState({
    MediaResource? resource,
    Uint8List? preview,
    BackgroundOperation? operation,
    @Default(0) double progress,
    @Default(false) bool changed,
    @Default(false) bool saved,
    AppFailure? error,
  }) = _BackgroundEditorState;

  bool get busy => operation != null;
}
