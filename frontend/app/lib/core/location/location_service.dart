import "../models/location.dart";

enum LocationFailure implements Exception {
  denied,
  blocked,
  servicesDisabled,
  clientUnavailable,
  unavailable,
  initializationFailed,
  timeout,
}

abstract interface class LocationService {
  Future<void> initialize();
  Future<Location> locate();
  bool get canOpenSettings;
  Future<bool> openSettings(LocationFailure failure);
}
