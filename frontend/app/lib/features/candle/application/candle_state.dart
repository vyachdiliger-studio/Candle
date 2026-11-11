import "../../resources/domain/media_resource.dart";
import "package:freezed_annotation/freezed_annotation.dart";

import "../domain/models/candle.dart";

part "candle_state.freezed.dart";

@freezed
abstract class CandleState with _$CandleState {
  const factory CandleState({
    @Default("") String message,
    required Candle? candle,
    MediaResource? draftBackground,
  }) = _CandleState;
}
