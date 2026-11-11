import "../../../resources/domain/media_resource.dart";
import "package:candle_frontend/core/models/location.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "candle.freezed.dart";

class CandleAuthor {
  final int id;
  final String? username;
  const CandleAuthor({required this.id, this.username});
  factory CandleAuthor.fromJson(Map<String, dynamic> json) => CandleAuthor(
    id: (json["id"] as num).toInt(),
    username: json["username"] as String?,
  );
  Map<String, dynamic> toJson() => {"id": id, "username": username};
}

@freezed
abstract class Candle with _$Candle {
  const factory Candle({
    required int id,
    required DateTime createdAt,
    required DateTime ignitedAt,
    required DateTime extinguishedAt,
    required Location? location,
    String? message,

    /// Where [location] is, as its author picked it; null when they didn't.
    String? address,
    @Default(0) int supportersCount,
    CandleAuthor? author,
    MediaResource? background,
  }) = _Candle;
}
