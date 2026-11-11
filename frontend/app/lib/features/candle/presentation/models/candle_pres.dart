import "package:freezed_annotation/freezed_annotation.dart";

import "../../domain/models/candle.dart";

part "candle_pres.freezed.dart";

@freezed
abstract class CandlePres with _$CandlePres {
  const CandlePres._();

  const factory CandlePres({
    required double burnProgress,
    required String? title,
    required Duration burnDurationLeft,
  }) = _CandlePres;

  bool get isBurning => burnProgress > 0;

  factory CandlePres.fromDomain({
    required Candle candle,
    required DateTime now,
  }) {
    final total = candle.extinguishedAt.difference(candle.ignitedAt).inMilliseconds;
    final passed = now.difference(candle.ignitedAt).inMilliseconds;

    final burnProgress = (total <= 0) ? 0.0 : (1 - (passed / total)).clamp(0.0, 1.0);
    final left = candle.extinguishedAt.isAfter(now)
        ? candle.extinguishedAt.difference(now)
        : Duration.zero;

    return CandlePres(
      burnProgress: burnProgress,
      title: candle.message,
      burnDurationLeft: left,
    );
  }
}
