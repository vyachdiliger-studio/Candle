import "package:candle_frontend/core/models/location.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "address_suggestion.freezed.dart";

@freezed
abstract class AddressSuggestion with _$AddressSuggestion {
  const factory AddressSuggestion({
    required String label,
    required Location location,
  }) = _AddressSuggestion;
}
