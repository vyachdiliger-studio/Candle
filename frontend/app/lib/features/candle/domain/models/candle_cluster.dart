import "package:candle_frontend/core/models/location.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "candle_cluster.freezed.dart";

@freezed
abstract class CandleCluster with _$CandleCluster {
  const CandleCluster._();

  const factory CandleCluster({
    required int count,
    required Location location,
    required int candleId,
    @Default(false) bool hasOwnCandle,
  }) = _CandleCluster;

  bool get isSingleCandle => count == 1;
}
