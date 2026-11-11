import "package:freezed_annotation/freezed_annotation.dart";

import "../../domain/models/candle.dart";

part "queue_state.freezed.dart";

@freezed
abstract class BoostQueueEntry with _$BoostQueueEntry {
  const factory BoostQueueEntry({
    @Default(0) int pending,
    @Default(false) bool isSubmitting,

    /// The server's view of the candle after the latest accepted batch; it
    /// already includes everyone else's taps.
    Candle? confirmed,
  }) = _BoostQueueEntry;
}

@freezed
abstract class BoostQueueState with _$BoostQueueState {
  const factory BoostQueueState({
    @Default({}) Map<int, BoostQueueEntry> entries,
  }) = _BoostQueueState;
}
