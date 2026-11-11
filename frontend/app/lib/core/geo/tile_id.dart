import "package:freezed_annotation/freezed_annotation.dart";

part "tile_id.freezed.dart";

@Freezed(toStringOverride: false)
abstract class TileId with _$TileId {
  const TileId._();

  const factory TileId(int z, int x, int y) = _TileId;

  @override
  String toString() => "$z/$x/$y";
}
