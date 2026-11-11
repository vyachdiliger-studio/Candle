import "package:candle_frontend/core/models/location.dart";

extension LocationExtension on Location {
  String get coordinatesLabel => "${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}";
}
