import "package:candle_frontend/core/config/app_config.dart";
import "package:candle_frontend/core/config/package_name_provider.dart";
import "package:candle_frontend/core/models/location.dart";
import "package:dartz/dartz.dart";
import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../domain/models/address_suggestion.dart";
import "../domain/remote_geocoding_repository.dart";

import "models/photon_feature_dto.dart";

class PhotonGeocodingRepository implements RemoteGeocodingRepository {
  final Dio dio;

  const PhotonGeocodingRepository(this.dio);

  static const _suggestionLimit = 5;
  static const _fetchLimit = 12;

  void _logError(String operation, Object e) {
    debugPrint("[GeocodingRepository] $operation failed: $e");
  }

  @override
  Future<Either<Unit, List<AddressSuggestion>>> search({
    required String query,
    Location? near,
  }) async {
    try {
      final res = await dio.get(
        "/api",
        queryParameters: {
          "q": query,
          "limit": _fetchLimit,
          if (near != null) "lat": near.latitude,
          if (near != null) "lon": near.longitude,
        },
      );

      return right(_suggestionsOf(res.data));
    } catch (e) {
      _logError("search", e);

      return left(unit);
    }
  }

  @override
  Future<Either<Unit, String?>> reverse(Location location) async {
    try {
      final res = await dio.get(
        "/reverse",
        queryParameters: {
          "lat": location.latitude,
          "lon": location.longitude,
          "limit": 1,
        },
      );

      final suggestions = _suggestionsOf(res.data);

      return right(suggestions.isEmpty ? null : suggestions.first.label);
    } catch (e) {
      _logError("reverse", e);

      return left(unit);
    }
  }

  List<AddressSuggestion> _suggestionsOf(dynamic data) {
    final features = data is Map ? data["features"] : null;

    if (features is! List) return const [];

    final labels = <String>{};

    return [
      for (final feature in features)
        if (feature is Map<String, dynamic>) ?PhotonFeatureDto.fromJson(feature).toDomain(),
    ].where((it) => labels.add(it.label)).take(_suggestionLimit).toList();
  }
}

final photonDioProvider = Provider(
  (ref) => Dio(
    BaseOptions(
      baseUrl: AppConfig.photonBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 8),
      // Photon answers 403 to the default "Dart/x.y (dart:io)" agent.
      headers: {"User-Agent": ref.watch(packageNameProvider)},
    ),
  ),
);

final geocodingRepositoryProvider = Provider<RemoteGeocodingRepository>((ref) {
  return PhotonGeocodingRepository(ref.watch(photonDioProvider));
});
