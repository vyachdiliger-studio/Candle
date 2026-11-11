import "package:candle_frontend/core/errors/app_failure.dart";
import "../../../core/security/session_epoch.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "gallery_preferences.dart";
import "candle_controller.dart";
import "../../auth/auth.dart";
import "../data/dio_candle_repository.dart";
import "../domain/models/candle.dart";
import "boost/queue.dart";
import "dart:async";

final galleryUserIdProvider = Provider<int?>(
  (ref) => switch (ref.watch(sessionControllerProvider).value) {
    SessionAuth(:final userId) => userId,
    _ => null,
  },
);

class CandleGalleryState {
  final List<Candle> mine;
  final List<Candle> recent;
  final int? selectedId;
  final AppFailure? warning;
  const CandleGalleryState({
    this.mine = const [],
    this.recent = const [],
    this.selectedId,
    this.warning,
  });
  List<Candle> get candles => [...mine, ...recent];
  Candle? get selected => candles.where((c) => c.id == selectedId).firstOrNull;
}

final candleGalleryProvider = AsyncNotifierProvider<CandleGalleryController, CandleGalleryState>(
  CandleGalleryController.new,
);

class CandleGalleryController extends AsyncNotifier<CandleGalleryState> {
  int? _userId;
  List<int> _history = [];
  final _closedRecent = <int>{};
  int _openRequest = 0;
  bool _refreshing = false;
  int _sessionEpoch = 0;
  bool get _isCurrent => ref.mounted && ref.read(sessionEpochProvider) == _sessionEpoch;

  void hideAuthor(int authorId) {
    ++_openRequest;
    final current = state.value;
    if (current == null) return;
    final mine = current.mine.where((c) => c.author?.id != authorId).toList();
    final recent = current.recent.where((c) => c.author?.id != authorId).toList();
    final selected = [...mine, ...recent].any((c) => c.id == current.selectedId)
        ? current.selectedId
        : null;
    state = AsyncData(CandleGalleryState(mine: mine, recent: recent, selectedId: selected));
  }

  @override
  Future<CandleGalleryState> build() async {
    ++_openRequest;
    _closedRecent.clear();
    _sessionEpoch = ref.watch(sessionEpochProvider);
    _userId = ref.watch(galleryUserIdProvider);
    return _load();
  }

  Future<CandleGalleryState> _load() async {
    final operationRef = ref;
    final userId = _userId;
    final repository = ref.read(candleRepositoryProvider);
    final preferences = ref.read(galleryStorageProvider);
    final history = (await preferences.history(userId).catchError((Object _) => null) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .where((id) => id > 0 && !_closedRecent.contains(id))
        .toSet()
        .take(30)
        .toList();
    if (!operationRef.mounted) throw const SessionChanged();
    _history = history;
    final mine = <Candle>[];
    AppFailure? warning;
    if (userId != null) {
      String? cursor;
      final seen = <String>{};
      do {
        final result = await repository.search(authorId: userId, status: "burning", cursor: cursor);
        if (!operationRef.mounted) throw const SessionChanged();
        final page = result.fold((_) => null, (page) => page);
        if (page == null) throw Exception("Unable to load your candles");
        mine.addAll(page.items);
        cursor = page.nextCursor;
        if (cursor != null && !seen.add(cursor)) throw Exception("Invalid pagination cursor");
      } while (cursor != null);
    }
    final recent = <Candle>[];
    if (history.isNotEmpty) {
      final result = await repository.search(ids: history, status: "burning", limit: 100);
      if (!operationRef.mounted) throw const SessionChanged();
      result.fold((_) => warning = AppFailure.recentCandlesFailed, (page) {
        final byId = {for (final candle in page.items) candle.id: candle};
        for (final id in history) {
          final candle = byId[id];
          if (candle != null && !(userId != null && candle.author?.id == userId)) {
            recent.add(candle);
          }
        }
      });
    }
    final uniqueMine = {for (final candle in mine) candle.id: candle}.values.toList();
    final lastId = await preferences.selection(userId).catchError((Object _) => null);
    if (!operationRef.mounted) throw const SessionChanged();
    final all = [...uniqueMine, ...recent];
    return CandleGalleryState(
      mine: uniqueMine,
      recent: recent,
      warning: warning,
      selectedId: all.any((c) => c.id == lastId) ? lastId : all.firstOrNull?.id,
    );
  }

  /// Reloads the lists in place, without a loading state, so thumbnails and
  /// burn times catch up after the app was away. Failures are ignored: the
  /// gallery on screen is still good.
  Future<void> refreshQuietly() async {
    final started = state.value;
    if (_refreshing || !_isCurrent || started == null) return;
    _refreshing = true;
    final epoch = _sessionEpoch;
    try {
      final fresh = await _load();
      final current = state.value;
      if (!_isCurrent || epoch != _sessionEpoch || current == null) return;
      final pendingTaps = ref.read(boostQueueProvider).entries;
      Candle keepLocal(Candle candle) {
        final local = current.candles.where((c) => c.id == candle.id).firstOrNull;
        return local != null && (pendingTaps[candle.id]?.pending ?? 0) > 0 ? local : candle;
      }

      final mine = fresh.mine.map(keepLocal).toList();
      // A failed recent lookup comes back empty with a warning; keep what we had.
      final recent = (fresh.warning != null ? current.recent : fresh.recent.map(keepLocal))
          .where((candle) => !_closedRecent.contains(candle.id))
          .toList();
      final selected = current.selected;
      if (selected != null && ![...mine, ...recent].any((c) => c.id == selected.id)) {
        // Keep the candle being looked at even if it just burned out.
        (current.mine.any((c) => c.id == selected.id) ? mine : recent).add(selected);
      }
      state = AsyncData(
        CandleGalleryState(
          mine: mine,
          recent: recent,
          selectedId: current.selectedId,
          warning: fresh.warning,
        ),
      );
    } catch (_) {
      // Keep showing the current gallery.
    } finally {
      _refreshing = false;
    }
  }

  void select(int? id, {bool sync = true}) {
    ++_openRequest;
    final current = state.value;
    if (!_isCurrent || current == null) return;
    state = AsyncData(
      CandleGalleryState(
        mine: current.mine,
        recent: current.recent,
        selectedId: id,
        warning: current.warning,
      ),
    );
    ref.read(galleryStorageProvider).select(_userId, _sessionEpoch, id).catchError((Object _) {});
    // The candle may have been boosted by others since it was last shown.
    if (sync && id != null) {
      unawaited(ref.read(candleControllerProvider(id).notifier).syncWithServer());
    }
  }

  Future<void> open(int id) async {
    final operationRef = ref;
    final epoch = ref.read(sessionEpochProvider);
    await future;
    if (!operationRef.mounted || ref.read(sessionEpochProvider) != epoch) return;
    final request = ++_openRequest;
    if (!operationRef.mounted || !_isCurrent || request != _openRequest) return;
    final result = await ref.read(candleRepositoryProvider).getById(id);
    if (!operationRef.mounted || !_isCurrent || request != _openRequest) return;
    final candle = result.fold((_) => null, (c) => c);
    if (candle == null) throw Exception("Candle unavailable");
    await add(candle);
    if (operationRef.mounted && _isCurrent) ref.invalidate(candleControllerProvider(id));
  }

  Future<void> add(Candle candle) async {
    final current = state.value;
    if (!_isCurrent || current == null) return;
    _closedRecent.remove(candle.id);
    final owned = _userId != null && candle.author?.id == _userId;
    final mine = [...current.mine];
    final recent = [...current.recent];
    final target = owned ? mine : recent;
    final index = target.indexWhere((c) => c.id == candle.id);
    if (index < 0) {
      target.add(candle);
    } else {
      target[index] = candle;
    }
    (owned ? recent : mine).removeWhere((c) => c.id == candle.id);
    state = AsyncData(
      CandleGalleryState(
        mine: mine,
        recent: recent,
        selectedId: candle.id,
        warning: current.warning,
      ),
    );
    select(candle.id, sync: false);
    if (!owned) {
      _history = [candle.id, ..._history.where((id) => id != candle.id)].take(30).toList();
      await ref
          .read(galleryStorageProvider)
          .saveHistory(_userId, _sessionEpoch, _history.map((id) => "$id").toList())
          .catchError((Object _) {});
    }
  }

  void closeRecent(int id) {
    final current = state.value;
    if (!_isCurrent ||
        current == null ||
        current.mine.any((candle) => candle.id == id) ||
        !current.recent.any((candle) => candle.id == id)) {
      return;
    }
    ++_openRequest;
    _closedRecent.add(id);
    _history.remove(id);
    final recent = current.recent.where((candle) => candle.id != id).toList();
    final remaining = [...current.mine, ...recent];
    final oldIndex = current.candles.indexWhere((candle) => candle.id == id);
    final selectedId = current.selectedId != id
        ? current.selectedId
        : remaining.isEmpty
        ? null
        : remaining[oldIndex.clamp(0, remaining.length - 1)].id;
    state = AsyncData(
      CandleGalleryState(
        mine: current.mine,
        recent: recent,
        selectedId: selectedId,
        warning: current.warning,
      ),
    );
    final storage = ref.read(galleryStorageProvider);
    storage
        .saveHistory(_userId, _sessionEpoch, _history.map((id) => "$id").toList())
        .catchError((Object _) {});
    storage.select(_userId, _sessionEpoch, selectedId).catchError((Object _) {});
  }

  void publish(Candle candle) {
    final current = state.value;
    if (!_isCurrent || current == null) return;
    state = AsyncData(
      CandleGalleryState(
        mine: current.mine.map((c) => c.id == candle.id ? candle : c).toList(),
        recent: current.recent.map((c) => c.id == candle.id ? candle : c).toList(),
        selectedId: current.selectedId,
        warning: current.warning,
      ),
    );
  }
}
