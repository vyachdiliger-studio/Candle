import "package:freezed_annotation/freezed_annotation.dart";

import "../models/location.dart";

part "location_dto.freezed.dart";
part "location_dto.g.dart";

@freezed
abstract class LocationDto with _$LocationDto {
  const LocationDto._();

  const factory LocationDto({
    required double latitude,
    required double longitude,
  }) = _LocationDto;

  factory LocationDto.fromJson(Map<String, dynamic> json) => _$LocationDtoFromJson(json);

  Location toDomain() => Location(latitude: latitude, longitude: longitude);

  static LocationDto fromDomain(Location c) =>
      LocationDto(latitude: c.latitude, longitude: c.longitude);
}
