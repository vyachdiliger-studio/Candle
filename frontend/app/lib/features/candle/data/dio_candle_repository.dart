import "package:dartz/dartz.dart";
import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:candle_frontend/core/dtos/location_dto.dart";
import "package:candle_frontend/core/models/location.dart";
import "package:candle_frontend/core/network/dio_provider.dart";

import "../domain/models/candle.dart";
import "../domain/models/candle_cluster.dart";
import "../domain/remote_candle_repository.dart";

import "models/candle_dto.dart";
import "models/tile_dto.dart";

class DioCandleRepository implements RemoteCandleRepository {
  final Dio dio;

  const DioCandleRepository(this.dio);

  void _logDioError(String operation, DioException e) {
    final status = e.response?.statusCode;
    final method = e.requestOptions.method;
    final path = e.requestOptions.path;

    debugPrint(
      "[CandleRepository] $operation failed: $method $path -> "
      "${status ?? e.type.name}${e.response?.data == null ? "" : " ${e.response?.data}"}",
    );
  }

  void _logError(String operation, Object e, StackTrace st) {
    debugPrint("[CandleRepository] $operation failed: $e\n$st");
  }

  @override
  Future<Either<Unit, CandlePage>> search({
    int? authorId,
    List<int>? ids,
    String? status,
    String? cursor,
    int limit = 100,
  }) async {
    try {
      final res = await dio.post(
        "/candles/search",
        data: {
          "filter": {
            "authorId": ?authorId,
            "ids": ?ids,
            "status": ?status,
          },
          "sort": "createdAtDesc",
          "limit": limit,
          "cursor": ?cursor,
        },
      );
      return right(
        CandlePage(
          (res.data["items"] as List)
              .map((it) => CandleDto.fromJson(it as Map<String, dynamic>).toDomain())
              .toList(),
          res.data["nextCursor"] as String?,
        ),
      );
    } on DioException catch (e) {
      _logDioError("search", e);
      return left(unit);
    } catch (e, st) {
      _logError("search", e, st);
      return left(unit);
    }
  }

  @override
  Future<Either<Unit, Candle>> create({String? message, String? backgroundResourceId}) async {
    try {
      final res = await dio.post(
        "/candles",
        data: {"message": message, "backgroundResourceId": ?backgroundResourceId},
      );

      final dto = CandleDto.fromJson(res.data);

      return right(dto.toDomain());
    } on DioException catch (e) {
      _logDioError("create", e);

      return left(unit);
    } catch (e, st) {
      _logError("create", e, st);

      return left(unit);
    }
  }

  @override
  Future<Either<Unit, Candle>> update({
    required int id,
    required String message,
  }) async {
    try {
      final res = await dio.patch("/candles/$id", data: {"message": message});

      final dto = CandleDto.fromJson(res.data);

      return right(dto.toDomain());
    } on DioException catch (e) {
      _logDioError("update", e);

      return left(unit);
    } catch (e, st) {
      _logError("update", e, st);

      return left(unit);
    }
  }

  @override
  Future<Either<Unit, Candle>> updateBackground({
    required int id,
    required String? resourceId,
  }) async {
    try {
      final response = await dio.patch("/candles/$id", data: {"backgroundResourceId": resourceId});
      return right(CandleDto.fromJson(response.data).toDomain());
    } on DioException catch (error) {
      _logDioError("updateBackground", error);
      return left(unit);
    }
  }

  @override
  Future<Either<Unit, Candle>> updateLocation({
    required int id,
    required Location location,
    String? address,
  }) async {
    try {
      final res = await dio.patch(
        "/candles/$id",
        // Always sent: a moved pin loses its old address unless a new one comes along.
        data: {"location": LocationDto.fromDomain(location).toJson(), "address": address},
      );

      final dto = CandleDto.fromJson(res.data);

      return right(dto.toDomain());
    } on DioException catch (e) {
      _logDioError("updateLocation", e);

      return left(unit);
    } catch (e, st) {
      _logError("updateLocation", e, st);

      return left(unit);
    }
  }

  @override
  Future<Either<Unit, Candle>> boost({
    required int id,
    required int taps,
  }) async {
    try {
      final res = await dio.post("/candles/$id/boost", data: {"taps": taps});

      final dto = CandleDto.fromJson(res.data);

      return right(dto.toDomain());
    } on DioException catch (e) {
      _logDioError("boost", e);

      return left(unit);
    } catch (e, st) {
      _logError("boost", e, st);

      return left(unit);
    }
  }

  @override
  Future<Either<Unit, List<CandleCluster>>> getTile({
    required int z,
    required int x,
    required int y,
    required int cellsPerTile,
  }) async {
    try {
      final res = await dio.get(
        "/candles/tiles/$z/$x/$y",
        queryParameters: {"cellsPerTile": cellsPerTile},
      );

      return right(TileDto.fromJson(res.data).toDomain());
    } on DioException catch (e) {
      _logDioError("getTile $z/$x/$y", e);

      return left(unit);
    } catch (e, st) {
      _logError("getTile $z/$x/$y", e, st);

      return left(unit);
    }
  }

  @override
  Future<Either<Unit, Candle>> getById(int id) async {
    try {
      final res = await dio.get("/candles/$id");

      final dto = CandleDto.fromJson(res.data);

      return right(dto.toDomain());
    } on DioException catch (e) {
      _logDioError("getById", e);

      return left(unit);
    } catch (e, st) {
      _logError("getById", e, st);

      return left(unit);
    }
  }
}

final candleRepositoryProvider = Provider<RemoteCandleRepository>((ref) {
  return DioCandleRepository(ref.watch(dioProvider));
});
