import "dart:async";

import "package:candle_frontend/core/models/location.dart";
import "package:candle_frontend/features/geocoding/data/photon_geocoding_repository.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "address_field_state.dart";

part "address_field_controller.g.dart";

@riverpod
class AddressFieldController extends _$AddressFieldController {
  late final repository = ref.watch(geocodingRepositoryProvider);

  var _isDisposed = false;

  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 400);

  static const _minQueryLength = 3;

  @override
  AddressFieldState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();

      _isDisposed = true;
    });

    return const AddressFieldState();
  }

  void textChanged(String text, {Location? near}) {
    _debounceTimer?.cancel();

    final query = text.trim();

    state = state.copyWith(hasText: query.isNotEmpty, isSynced: false, label: null);

    if (query.length < _minQueryLength) {
      state = state.copyWith(suggestions: const [], isSearching: false);

      return;
    }

    _debounceTimer = Timer(_debounceDuration, () => _search(query, near));
  }

  Future<void> _search(String query, Location? near) async {
    state = state.copyWith(isSearching: true);

    final result = await repository.search(query: query, near: near);

    if (_isDisposed || state.isSynced) return;

    state = result.fold(
      (_) => state.copyWith(isSearching: false, suggestions: const []),
      (suggestions) => state.copyWith(isSearching: false, suggestions: suggestions),
    );
  }

  /// Begins with an address the candle already has, which still matches its pin.
  void startWith(String? address) {
    if (address == null) return;

    state = state.copyWith(hasText: true, isSynced: true, label: address);
  }

  void suggestionPicked(String label) {
    _debounceTimer?.cancel();

    state = state.copyWith(
      hasText: true,
      isSynced: true,
      label: label,
      suggestions: const [],
      isSearching: false,
    );
  }

  void clear() {
    _debounceTimer?.cancel();

    state = const AddressFieldState();
  }

  void markStale() {
    if (!state.isSynced) return;

    state = state.copyWith(isSynced: false, label: null);
  }

  Future<String?> restoreFromCoordinates(Location location) async {
    _debounceTimer?.cancel();

    state = state.copyWith(isResolving: true, suggestions: const []);

    final result = await repository.reverse(location);

    if (_isDisposed) return null;

    final label = result.fold((_) => null, (label) => label);

    state = state.copyWith(
      isResolving: false,
      hasText: label != null,
      isSynced: label != null,
      label: label,
    );

    return label;
  }
}
