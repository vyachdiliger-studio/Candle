import "../../../../core/security/session_epoch.dart";
import "dart:async";
import "dart:math";

import "package:flutter_riverpod/flutter_riverpod.dart" show Provider;
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../data/dio_candle_repository.dart";
import "../../domain/remote_candle_repository.dart";

import "queue_state.dart";
import "queue_store.dart";

part "queue.g.dart";

final boostQueueStoreProvider = Provider((ref) => NoopBoostQueueStore());

@Riverpod(keepAlive: true)
class BoostQueue extends _$BoostQueue {
  static const _retryDuration = Duration(seconds: 5);
  static const _debounceDuration = Duration(seconds: 1);

  final _debounceTimers = <int, Timer>{};
  final _retryTimers = <int, Timer>{};

  bool _initialized = false;
  int _epoch = 0;
  bool get _isCurrent => ref.mounted && ref.read(sessionEpochProvider) == _epoch;

  BoostQueueStore get _store => ref.read(boostQueueStoreProvider);
  RemoteCandleRepository get _repository => ref.read(candleRepositoryProvider);

  @override
  BoostQueueState build() {
    _epoch = ref.watch(sessionEpochProvider);
    ref.onDispose(() {
      for (final timer in _retryTimers.values) {
        timer.cancel();
      }
      for (final timer in _debounceTimers.values) {
        timer.cancel();
      }

      _retryTimers.clear();
      _debounceTimers.clear();
      _initialized = false;
    });

    if (!_initialized) {
      _initialized = true;

      unawaited(_init());
    }

    return const BoostQueueState();
  }

  Future<void> _init() async {
    final operationRef = ref;
    final loadedPending = await _store.loadPending();

    if (!operationRef.mounted || !_isCurrent || loadedPending.isEmpty) return;

    state = state.copyWith(
      entries: {
        ...state.entries,
        ...Map.fromEntries(
          loadedPending.entries.where((e) => e.value > 0).map((entry) {
            _ensureRetryTicker(entry.key);
            _scheduleDebouncedSubmit(entry.key);

            final existing = state.entries[entry.key] ?? const BoostQueueEntry();

            return MapEntry(
              entry.key,
              existing.copyWith(pending: existing.pending + entry.value),
            );
          }),
        ),
      },
    );
  }

  BoostQueueEntry entryOf(int candleId) => state.entries[candleId] ?? const BoostQueueEntry();

  int pendingOf(int candleId) => entryOf(candleId).pending;

  bool isSubmittingOf(int candleId) => entryOf(candleId).isSubmitting;

  void queueTap(int candleId, {int taps = 1}) {
    if (!_isCurrent || taps <= 0) return;

    state = _updateEntry(
      candleId,
      (current) => current.copyWith(pending: current.pending + taps),
    );

    _persist();
    _scheduleDebouncedSubmit(candleId);
    _ensureRetryTicker(candleId);
  }

  Future<void> flush(int candleId) => _trySubmit(candleId);

  void clear(int candleId) {
    _debounceTimers.remove(candleId)?.cancel();
    _retryTimers.remove(candleId)?.cancel();

    if (!state.entries.containsKey(candleId)) return;

    state = state.copyWith(entries: {...state.entries}..remove(candleId));

    _persist();
  }

  BoostQueueState _updateEntry(
    int candleId,
    BoostQueueEntry Function(BoostQueueEntry current) update,
  ) {
    final current = state.entries[candleId] ?? const BoostQueueEntry();
    final updated = update(current);

    return state.copyWith(entries: {...state.entries, candleId: updated});
  }

  void _scheduleDebouncedSubmit(int candleId) {
    _debounceTimers.remove(candleId)?.cancel();

    _debounceTimers[candleId] = Timer(
      _debounceDuration,
      () => _trySubmit(candleId),
    );
  }

  void _ensureRetryTicker(int candleId) {
    _retryTimers[candleId] ??= Timer.periodic(_retryDuration, (_) {
      final current = entryOf(candleId);

      if (current.pending > 0 && !current.isSubmitting) {
        _trySubmit(candleId);
      }
    });
  }

  void _maybeStopRetryTicker(int candleId) {
    final current = entryOf(candleId);

    if (current.pending == 0 && !current.isSubmitting) {
      _retryTimers.remove(candleId)?.cancel();
    }
  }

  Future<void> _trySubmit(int candleId) async {
    if (!_isCurrent) return;
    final operationRef = ref;
    final current = entryOf(candleId);

    if (current.isSubmitting) return;
    if (current.pending <= 0) return;

    final tapsToSend = current.pending;

    state = _updateEntry(candleId, (it) => it.copyWith(isSubmitting: true));

    try {
      final result = await _repository.boost(id: candleId, taps: tapsToSend);

      if (!operationRef.mounted || !_isCurrent) return;
      result.fold((_) {}, (serverCandle) {
        final latest = entryOf(candleId);
        final pendingLeft = max(0, latest.pending - tapsToSend);

        state = _updateEntry(
          candleId,
          (it) => it.copyWith(pending: pendingLeft, isSubmitting: false, confirmed: serverCandle),
        );

        _persist();

        if (pendingLeft == 0) {
          _maybeStopRetryTicker(candleId);
        } else {
          _scheduleDebouncedSubmit(candleId);
        }
      });
    } finally {
      if (operationRef.mounted && _isCurrent) {
        final latest = entryOf(candleId);

        if (latest.isSubmitting) {
          state = _updateEntry(
            candleId,
            (it) => it.copyWith(isSubmitting: false),
          );
        }
      }
    }
  }

  void _persist() {
    final pending = Map.fromEntries(
      state.entries.entries
          .where((e) => e.value.pending > 0)
          .map((e) => MapEntry(e.key, e.value.pending)),
    );

    unawaited(_store.savePending(pending));
  }
}
