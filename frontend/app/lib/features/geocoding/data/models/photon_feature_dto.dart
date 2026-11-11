import "package:candle_frontend/features/geocoding/domain/models/address_suggestion.dart";
import "package:freezed_annotation/freezed_annotation.dart";

import "photon_geometry_dto.dart";
import "photon_properties_dto.dart";

part "photon_feature_dto.freezed.dart";
part "photon_feature_dto.g.dart";

@freezed
abstract class PhotonFeatureDto with _$PhotonFeatureDto {
  const PhotonFeatureDto._();

  const factory PhotonFeatureDto({
    required PhotonGeometryDto geometry,
    required PhotonPropertiesDto properties,
  }) = _PhotonFeatureDto;

  factory PhotonFeatureDto.fromJson(Map<String, dynamic> json) => _$PhotonFeatureDtoFromJson(json);

  AddressSuggestion? toDomain() {
    final label = properties.label;
    final location = geometry.toDomain();

    if (label == null || location == null) return null;

    return AddressSuggestion(label: label, location: location);
  }
}
