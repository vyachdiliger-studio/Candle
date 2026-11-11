import "dart:async";

import "package:candle_frontend/core/models/location.dart";
import "package:candle_frontend/core/security/session_epoch.dart";
import "package:candle_frontend/features/candle/data/dio_candle_repository.dart";
import "package:candle_frontend/features/candle/domain/models/candle_cluster.dart";
import "package:candle_frontend/features/candle/domain/remote_candle_repository.dart";
import "package:candle_frontend/features/map/application/map_controller.dart";
import "package:dartz/dartz.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";

class TileRepository implements RemoteCandleRepository {
  final requests = <Completer<Either<Unit, List<CandleCluster>>>>[];

  @override
  Future<Either<Unit, List<CandleCluster>>> getTile({
    required int z,
    required int x,
    required int y,
    required int cellsPerTile,
  }) {
    final result = Completer<Either<Unit, List<CandleCluster>>>();
    requests.add(result);
    return result.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const viewport = (west: -10.0, south: -10.0, east: 10.0, north: 10.0);
  const own = CandleCluster(
    count: 2,
    candleId: 1,
    location: Location(latitude: 0, longitude: 0),
    hasOwnCandle: true,
  );

  for (final pending in [false, true]) {
    test(
      "changing sessions drops ownership from cached and in-flight tiles (pending=$pending)",
      () async {
        final repository = TileRepository();
        final container = ProviderContainer(
          overrides: [
            candleRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);
        await container.read(mapControllerProvider.future);
        final first = container
            .read(mapControllerProvider.notifier)
            .loadViewport(zoom: 1, viewport: viewport);
        expect(repository.requests, hasLength(1));
        if (!pending) {
          repository.requests.first.complete(right([own]));
          await first;
          expect(container.read(mapControllerProvider).value!.clusters.single.hasOwnCandle, isTrue);
        }

        container.read(sessionEpochProvider.notifier).advance();
        await container.read(mapControllerProvider.future);
        expect(container.read(mapControllerProvider).value!.clusters, isEmpty);
        final next = container
            .read(mapControllerProvider.notifier)
            .loadViewport(zoom: 1, viewport: viewport);
        expect(repository.requests, hasLength(2));
        if (pending) {
          repository.requests.first.complete(right([own]));
          await first;
        }
        repository.requests.last.complete(right([own.copyWith(hasOwnCandle: false)]));
        await next;
        expect(container.read(mapControllerProvider).value!.clusters.single.hasOwnCandle, isFalse);
      },
    );
  }
}
