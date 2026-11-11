import "package:candle_frontend/common/utils/string_extension.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "photon_properties_dto.freezed.dart";
part "photon_properties_dto.g.dart";

@freezed
abstract class PhotonPropertiesDto with _$PhotonPropertiesDto {
  const PhotonPropertiesDto._();

  const factory PhotonPropertiesDto({
    String? name,
    String? street,
    String? housenumber,
    String? city,
    String? district,
    String? state,
    String? country,
  }) = _PhotonPropertiesDto;

  factory PhotonPropertiesDto.fromJson(Map<String, dynamic> json) =>
      _$PhotonPropertiesDtoFromJson(json);

  String? get label => [
    _head,
    city ?? district,
    country,
  ].whereType<String>().join(", ").nullIfEmpty();

  String? get _head => name ?? [street, housenumber].whereType<String>().join(" ").nullIfEmpty();
}
