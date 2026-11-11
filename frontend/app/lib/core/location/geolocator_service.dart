import "dart:async";
import "package:flutter/foundation.dart";
import "package:geolocator/geolocator.dart";
import "../models/location.dart";
import "location_service.dart";

class GeolocatorService implements LocationService {
  @override
  Future<void> initialize() async {}

  @override
  bool get canOpenSettings => !kIsWeb;

  @override
  Future<bool> openSettings(LocationFailure failure) => failure == LocationFailure.servicesDisabled
      ? Geolocator.openLocationSettings()
      : Geolocator.openAppSettings();

  @override
  Future<Location> locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw LocationFailure.servicesDisabled;
      }
      var permission = await Geolocator.checkPermission();
      if (!kIsWeb && permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) throw LocationFailure.blocked;
      if (!kIsWeb && permission == LocationPermission.denied) throw LocationFailure.denied;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return Location(latitude: position.latitude, longitude: position.longitude);
    } on TimeoutException {
      throw LocationFailure.timeout;
    } on LocationServiceDisabledException {
      throw LocationFailure.servicesDisabled;
    } on PermissionDeniedException {
      throw kIsWeb ? LocationFailure.blocked : LocationFailure.denied;
    }
  }
}
