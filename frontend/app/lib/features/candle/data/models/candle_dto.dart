import "../../../resources/domain/media_resource.dart";
import "../../../resources/data/media_resource_dto.dart";
import "package:candle_frontend/core/dtos/location_dto.dart";
import "package:dart_scope_functions/dart_scope_functions.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "../../domain/models/candle.dart";

part "candle_dto.freezed.dart";
part "candle_dto.g.dart";

@freezed
abstract class CandleDto with _$CandleDto {
  const CandleDto._();

  const factory CandleDto({
    required int id,
    required DateTime createdAt,
    required DateTime ignitedAt,
    required DateTime extinguishedAt,
    required LocationDto? location,
    String? message,
    String? address,
    @Default(0) int supportersCount,
    @Default(0) int commentsCount,
    CandleAuthor? author,
    @JsonKey(fromJson: _backgroundFromJson, toJson: _backgroundToJson) MediaResource? background,
  }) = _CandleDto;

  factory CandleDto.fromJson(Map<String, dynamic> json) => _$CandleDtoFromJson(json);

  Candle toDomain() => Candle(
    id: id,
    author: author,
    supportersCount: supportersCount,
    commentsCount: commentsCount,
    background: background,
    createdAt: createdAt,
    ignitedAt: ignitedAt,
    extinguishedAt: extinguishedAt,
    message: message,
    address: address,
    location: location?.toDomain(),
  );

  static CandleDto fromDomain(Candle c) => CandleDto(
    id: c.id,
    author: c.author,
    supportersCount: c.supportersCount,
    commentsCount: c.commentsCount,
    background: c.background,
    createdAt: c.createdAt,
    ignitedAt: c.ignitedAt,
    extinguishedAt: c.extinguishedAt,
    message: c.message,
    address: c.address,
    location: c.location?.let(LocationDto.fromDomain),
  );
}

MediaResource? _backgroundFromJson(Map<String, dynamic>? json) =>
    json == null ? null : MediaResourceDto(json).toDomain();
Map<String, dynamic>? _backgroundToJson(MediaResource? resource) =>
    resource == null ? null : MediaResourceDto.fromDomain(resource);
