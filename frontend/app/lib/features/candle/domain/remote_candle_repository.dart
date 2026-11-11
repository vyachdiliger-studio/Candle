import "package:candle_frontend/core/models/location.dart";

import "models/candle.dart";
import "models/candle_cluster.dart";
import "package:dartz/dartz.dart";

class CandlePage {
  final List<Candle> items;
  final String? nextCursor;
  const CandlePage(this.items, this.nextCursor);
}

abstract class RemoteCandleRepository {
  Future<Either<Unit, CandlePage>> search({
    int? authorId,
    List<int>? ids,
    String? status,
    String? cursor,
    int limit = 30,
  });
  Future<Either<Unit, Candle>> getById(int id);
  Future<Either<Unit, Candle>> create({String? message, String? backgroundResourceId});
  Future<Either<Unit, Candle>> update({
    required int id,
    required String message,
  });
  Future<Either<Unit, Candle>> updateBackground({required int id, required String? resourceId});
  Future<Either<Unit, Candle>> updateLocation({
    required int id,
    required Location location,
    String? address,
  });
  Future<Either<Unit, Candle>> boost({required int id, required int taps});
  Future<Either<Unit, List<CandleCluster>>> getTile({
    required int z,
    required int x,
    required int y,
    required int cellsPerTile,
  });
}
