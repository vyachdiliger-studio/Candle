import "dart:async";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:candle_frontend/core/location/location_controller.dart";
import "package:candle_frontend/core/location/location_service.dart";
import "package:candle_frontend/core/models/location.dart";

class FakeLocationService implements LocationService {
  var calls = 0;
  var initializations = 0;
  var result = Completer<Location>();

  @override
  Future<void> initialize() async {
    initializations++;
  }

  @override
  Future<Location> locate() {
    calls++;
    return result.future;
  }

  @override
  bool get canOpenSettings => false;

  @override
  Future<bool> openSettings(LocationFailure failure) async => false;
}

void main() {
  test("startup initializes once without requesting coordinates or permissions", () async {
    final service = FakeLocationService();
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);
    await container.read(locationInitializationProvider.future);
    await container.read(locationInitializationProvider.future);
    expect(service.initializations, 1);
    expect(service.calls, 0);
  });
  test("concurrent location requests share one platform request", () async {
    final service = FakeLocationService();
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(locationControllerProvider.notifier);
    final first = controller.locate();
    final second = controller.locate();
    expect(service.calls, 1);
    expect(container.read(locationControllerProvider).isLoading, isTrue);
    const position = Location(latitude: 43, longitude: 76);
    service.result.complete(position);
    expect(await first, position);
    expect(await second, position);
    expect(container.read(locationControllerProvider).value, position);
  });

  test("permission denial ends loading and allows a new request", () async {
    final service = FakeLocationService();
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(locationControllerProvider.notifier);
    final denied = controller.locate();
    service.result.completeError(LocationFailure.blocked);
    expect(await denied, isNull);
    expect(container.read(locationControllerProvider).error, LocationFailure.blocked);
    expect(container.read(locationControllerProvider).isLoading, isFalse);
    service.result = Completer<Location>();
    final retry = controller.locate();
    service.result.complete(const Location(latitude: 0, longitude: 0));
    expect(await retry, isNotNull);
    expect(service.calls, 2);
  });
}
