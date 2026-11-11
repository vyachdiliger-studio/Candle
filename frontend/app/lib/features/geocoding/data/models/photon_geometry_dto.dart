import "package:candle_frontend/core/models/location.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "photon_geometry_dto.freezed.dart";
part "photon_geometry_dto.g.dart";

@freezed
abstract class PhotonGeometryDto with _$PhotonGeometryDto {
  const PhotonGeometryDto._();

  const factory PhotonGeometryDto({required List<num> coordinates}) = _PhotonGeometryDto;

  factory PhotonGeometryDto.fromJson(Map<String, dynamic> json) =>
      _$PhotonGeometryDtoFromJson(json);

  // GeoJSON orders coordinates as [longitude, latitude], not the other way round.
  Location? toDomain() => coordinates.length < 2
      ? null
      : Location(
          latitude: coordinates[1].toDouble(),
          longitude: coordinates[0].toDouble(),
        );
}
