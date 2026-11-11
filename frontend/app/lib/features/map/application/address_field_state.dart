import "package:candle_frontend/features/geocoding/domain/models/address_suggestion.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "address_field_state.freezed.dart";

@freezed
abstract class AddressFieldState with _$AddressFieldState {
  const AddressFieldState._();

  const factory AddressFieldState({
    @Default(false) bool hasText,
    @Default(false) bool isSynced,
    @Default([]) List<AddressSuggestion> suggestions,
    @Default(false) bool isSearching,
    @Default(false) bool isResolving,

    /// The address text, while it still describes the pin; null once it doesn't.
    String? label,
  }) = _AddressFieldState;

  bool get canClear => hasText;

  bool get canRestore => !isSynced && !isResolving;
}
