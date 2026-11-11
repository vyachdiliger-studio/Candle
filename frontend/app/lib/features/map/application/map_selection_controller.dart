import "/core/security/session_epoch.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "package:candle_frontend/features/candle/candle.dart";

part "map_selection_controller.g.dart";

@Riverpod(keepAlive: true)
class MapSelection extends _$MapSelection {
  @override
  Candle? build() {
    ref.watch(sessionEpochProvider);
    return null;
  }

  void select(Candle candle) => state = candle;

  void clear() => state = null;

  Future<Candle?> selectById(int id) async {
    final operationRef = ref;
    final result = await ref.read(candleRepositoryProvider).getById(id);

    if (!operationRef.mounted) return null;
    return result.fold((_) => null, (candle) => state = candle);
  }
}
