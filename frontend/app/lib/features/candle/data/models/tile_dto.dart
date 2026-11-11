import "package:candle_frontend/features/candle/candle.dart";
import "package:freezed_annotation/freezed_annotation.dart";

import "cluster_dto.dart";

part "tile_dto.freezed.dart";
part "tile_dto.g.dart";

@freezed
abstract class TileDto with _$TileDto {
  const TileDto._();

  const factory TileDto({
    required int z,
    required int x,
    required int y,
    required int cellsPerTile,
    required List<ClusterDto> clusters,
  }) = _TileDto;

  factory TileDto.fromJson(Map<String, dynamic> json) => _$TileDtoFromJson(json);

  List<CandleCluster> toDomain() => clusters.map((c) => c.toDomain()).toList();
}
