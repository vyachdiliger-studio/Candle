import "dart:async";
import "dart:js_interop";
import "package:flutter/foundation.dart";
import "../models/location.dart";
import "location_service.dart";

@JS("Telegram.WebApp")
external _WebApp? get _webApp;

extension type _WebApp(JSObject _) implements JSObject {
  external bool isVersionAtLeast(String version);
  @JS("LocationManager")
  external _LocationManager? get locationManager;
}

extension type _LocationManager(JSObject _) implements JSObject {
  external bool get isInited;
  external bool get isLocationAvailable;
  external bool get isAccessRequested;
  external bool get isAccessGranted;
  external void init(JSFunction callback);
  external void getLocation(JSFunction callback);
  external void openSettings();
}

extension type _Coordinates(JSObject _) implements JSObject {
  external double get latitude;
  external double get longitude;
}

class TelegramLocationService implements LocationService {
  _LocationManager? get _manager {
    final app = _webApp;
    return app != null && app.isVersionAtLeast("8.0") ? app.locationManager : null;
  }

  @override
  bool get canOpenSettings {
    final manager = _manager;
    return manager != null &&
        manager.isInited &&
        manager.isLocationAvailable &&
        manager.isAccessRequested &&
        !manager.isAccessGranted;
  }

  @override
  Future<bool> openSettings(LocationFailure failure) {
    final manager = _manager;
    if (manager == null) return Future.value(false);
    manager.openSettings();
    return Future.value(true);
  }

  Future<void>? _initialization;

  @override
  Future<void> initialize() {
    final manager = _manager;
    if (manager == null) return Future.error(LocationFailure.unavailable);
    if (manager.isInited) return Future.value();
    return _initialization ??= _initialize(manager);
  }

  Future<void> _initialize(_LocationManager manager) async {
    final ready = Completer<void>();
    manager.init(
      (() {
        if (!ready.isCompleted) ready.complete();
      }).toJS,
    );
    try {
      await ready.future.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      debugPrint("[Location] Telegram LocationManager initialization received no response");
      throw LocationFailure.initializationFailed;
    }
  }

  @override
  Future<Location> locate() async {
    await initialize();
    final manager = _manager!;
    try {
      if (!manager.isLocationAvailable) throw LocationFailure.clientUnavailable;
      if (manager.isAccessRequested && !manager.isAccessGranted) {
        throw LocationFailure.blocked;
      }
      final result = Completer<Location>();
      manager.getLocation(
        ((_Coordinates? coordinates) {
          if (result.isCompleted) return;
          if (coordinates == null) {
            result.completeError(
              manager.isAccessGranted ? LocationFailure.unavailable : LocationFailure.blocked,
            );
          } else {
            result.complete(
              Location(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude,
              ),
            );
          }
        }).toJS,
      );
      return await result.future.timeout(const Duration(seconds: 30));
    } on TimeoutException {
      debugPrint("[Location] Telegram coordinate request received no response");
      throw LocationFailure.timeout;
    }
  }
}
