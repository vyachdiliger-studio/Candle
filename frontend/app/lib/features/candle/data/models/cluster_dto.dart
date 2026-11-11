import "package:candle_frontend/core/dtos/location_dto.dart";
import "package:candle_frontend/features/candle/candle.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "cluster_dto.freezed.dart";
part "cluster_dto.g.dart";

@freezed
abstract class ClusterDto with _$ClusterDto {
  const ClusterDto._();

  const factory ClusterDto({
    required int count,
    required LocationDto location,
    required int candleId,
    @Default(false) bool hasOwnCandle,
  }) = _ClusterDto;

  factory ClusterDto.fromJson(Map<String, dynamic> json) => _$ClusterDtoFromJson(json);

  CandleCluster toDomain() => CandleCluster(
    count: count,
    location: location.toDomain(),
    candleId: candleId,
    hasOwnCandle: hasOwnCandle,
  );
}
