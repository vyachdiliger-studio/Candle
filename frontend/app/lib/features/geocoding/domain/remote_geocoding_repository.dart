import "package:candle_frontend/core/models/location.dart";
import "package:dartz/dartz.dart";

import "models/address_suggestion.dart";

abstract class RemoteGeocodingRepository {
  Future<Either<Unit, List<AddressSuggestion>>> search({
    required String query,
    Location? near,
  });

  Future<Either<Unit, String?>> reverse(Location location);
}
