import "package:hooks_riverpod/hooks_riverpod.dart";
import "../models/location.dart";
import "location_service.dart";
import "location_service_factory.dart";

final locationServiceProvider = Provider<LocationService>((ref) => createLocationService());
final locationInitializationProvider = FutureProvider<void>(
  (ref) => ref.watch(locationServiceProvider).initialize(),
);

final locationControllerProvider = NotifierProvider<LocationController, AsyncValue<Location?>>(
  LocationController.new,
);

class LocationController extends Notifier<AsyncValue<Location?>> {
  Future<Location?>? _pending;

  @override
  AsyncValue<Location?> build() => const AsyncData(null);

  Future<Location?> locate() => _pending ??= _locate().whenComplete(() => _pending = null);

  Future<Location?> _locate() async {
    state = const AsyncLoading();
    try {
      final location = await ref.read(locationServiceProvider).locate();
      if (ref.mounted) state = AsyncData(location);
      return location;
    } catch (error, stack) {
      if (ref.mounted) {
        state = AsyncError(error is LocationFailure ? error : LocationFailure.unavailable, stack);
      }
      return null;
    }
  }
}
