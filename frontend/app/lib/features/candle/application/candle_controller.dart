import "package:candle_frontend/core/errors/app_failure.dart";
import "dart:async";

import "../../resources/domain/media_resource.dart";
import "../../../core/security/session_epoch.dart";
import "package:candle_frontend/common/utils/string_extension.dart";
import "package:dart_scope_functions/dart_scope_functions.dart";
import "package:flutter_riverpod/flutter_riverpod.dart" show ProviderListenableSelect;
import "package:riverpod_annotation/riverpod_annotation.dart";

import "candle_state.dart";
import "candle_gallery_controller.dart";
import "../domain/models/candle.dart";
import "../domain/remote_candle_repository.dart";
import "../data/dio_candle_repository.dart";

import "boost/queue.dart";

part "candle_controller.g.dart";

@Riverpod(keepAlive: true)
class CandleController extends _$CandleController {
  /// Counts server confirmations of our own taps. A plain fetch that started
  /// before one landed is older than it, so its result must be dropped.
  int _confirmations = 0;

  @override
  Future<CandleState> build(int? candleId) async {
    ref.watch(sessionEpochProvider);
    final operationRef = ref;
    ref.watch(galleryUserIdProvider);
    if (candleId == null) return const CandleState(candle: null);
    ref.listen(
      boostQueueProvider.select((queue) => queue.entries[candleId]?.confirmed),
      (_, confirmed) {
        if (confirmed == null) return;
        _confirmations++;
        _applyServerState(confirmed);
      },
    );
    final gallery = ref.read(candleGalleryProvider);
    final cached = (gallery.isLoading ? null : gallery.value)?.candles
        .where((c) => c.id == candleId)
        .firstOrNull;
    if (cached != null) {
      // The gallery copy may be stale; show it now and catch up quietly.
      Timer.run(syncWithServer);
      return CandleState(candle: cached, message: cached.message ?? "");
    }
    final result = await _repository.getById(candleId);
    if (!operationRef.mounted) throw const SessionChanged();

    return result.fold(
      (_) => throw Exception("failed to load candle"),
      (candle) =>
          CandleState(candle: _applyPendingLocalBoosts(candle), message: candle.message ?? ""),
    );
  }

  void refresh() => ref.invalidateSelf(asReload: true);

  /// Pulls the candle's current state, e.g. taps other people made, without
  /// any loading state: the screen just picks up the new times.
  Future<void> syncWithServer() async {
    final id = candleId;
    if (id == null || !ref.mounted || state.value?.candle == null) return;
    final operationRef = ref;
    final confirmationsBefore = _confirmations;
    final result = await _repository.getById(id);
    if (!operationRef.mounted || confirmationsBefore != _confirmations) return;
    result.fold((_) {}, _applyServerState);
  }

  Future<void> onTap() async {
    final current = state.value;

    if (current == null || ref.read(galleryUserIdProvider) == null) return;

    final candle = current.candle;

    if (candle == null) {
      if (_isActiveScreen) await _create(current.message, current.draftBackground?.id);

      return;
    }

    if (candle.extinguishedAt.isBefore(DateTime.now())) {
      return;
    }

    _update((it) => it.copyWith(candle: _localBoostBy(candle, seconds: 1)));

    _boostQueue.queueTap(candle.id, taps: 1);
  }

  void messageUpdated(String message) {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(message: message));
  }

  void cancelMessageEditing() {
    final current = state.value;
    final candle = current?.candle;
    if (current == null || candle == null) return;

    state = AsyncData(current.copyWith(message: candle.message ?? ""));
  }

  Future<void> saveMessage() async {
    final current = state.value;

    if (current == null) return;

    final candleOwner = current.candle?.author?.id;
    if (current.candle != null && candleOwner != ref.read(galleryUserIdProvider)) return;
    final message = current.message;

    final candle = current.candle;

    if (candle == null) return;
    if (message.trim() == (candle.message ?? "")) return;

    final operationRef = ref;
    final result = await _repository.update(id: candle.id, message: message);

    if (!operationRef.mounted) return;
    result.fold(
      (_) => throw Exception("Failed to update message"),
      (serverCandle) => _publish(serverCandle),
    );
  }

  Future<void> setBackground(MediaResource? resource) async {
    final current = state.value;
    if (current == null) throw AppFailure.candleNotLoaded;
    final userId = ref.read(galleryUserIdProvider);
    if (userId == null) throw AppFailure.backgroundSignInRequired;
    if (current.candle == null) {
      state = AsyncData(current.copyWith(draftBackground: resource));
      return;
    }
    if (current.candle!.author?.id != userId) {
      throw AppFailure.backgroundAuthorOnly;
    }
    final operationRef = ref;
    final result = await _repository.updateBackground(
      id: current.candle!.id,
      resourceId: resource?.id,
    );
    if (!operationRef.mounted) return;
    result.fold((_) => throw AppFailure.backgroundSaveFailed, _publish);
  }

  Future<void> _create(String message, String? backgroundResourceId) async {
    final operationRef = ref;
    final result = await _repository.create(
      message: message.nullIfEmpty(),
      backgroundResourceId: backgroundResourceId,
    );
    final candle = result.fold((_) => null, (c) => c);
    if (candle == null) throw Exception("Failed to light candle");
    if (!operationRef.mounted) return;
    await ref.read(candleGalleryProvider.notifier).add(candle);
    if (operationRef.mounted) state = const AsyncData(CandleState(candle: null));
  }

  /// Replaces the candle with the server's copy, keeping taps that haven't
  /// been sent yet and a message the user is in the middle of editing.
  void _applyServerState(Candle server) {
    final current = state.value;
    final previous = current?.candle;
    if (current == null || previous == null) return;
    // Nothing can extend an extinguished candle, so queued taps would only be
    // rejected and retried forever.
    if (!server.extinguishedAt.isAfter(DateTime.now())) _boostQueue.clear(server.id);
    final merged = _applyPendingLocalBoosts(server)!;
    final editing = current.message != (previous.message ?? "");
    state = AsyncData(
      current.copyWith(candle: merged, message: editing ? current.message : server.message ?? ""),
    );
    ref.read(candleGalleryProvider.notifier).publish(merged);
  }

  void _publish(Candle candle) {
    final updated = _applyPendingLocalBoosts(candle)!;
    state = AsyncValue.data(CandleState(candle: updated, message: updated.message ?? ""));
    ref.read(candleGalleryProvider.notifier).publish(updated);
  }

  void _update(CandleState Function(CandleState state) transform) {
    final current = state.value;
    if (current == null) return;
    final next = transform(current);
    state = AsyncData(next);
    if (next.candle != null) ref.read(candleGalleryProvider.notifier).publish(next.candle!);
  }

  Candle? _applyPendingLocalBoosts(Candle? candle) => candle?.let((it) {
    final pending = _boostQueue.pendingOf(it.id);

    return pending <= 0 ? it : _localBoostBy(it, seconds: pending);
  });

  Candle _localBoostBy(Candle candle, {required int seconds}) {
    if (seconds <= 0) return candle;

    final now = DateTime.now();
    final delta = Duration(seconds: seconds);

    final proposedIgnited = candle.ignitedAt.add(delta);

    return candle.copyWith(
      extinguishedAt: candle.extinguishedAt.add(delta),
      ignitedAt: proposedIgnited.isBefore(now) ? proposedIgnited : now,
    );
  }

  BoostQueue get _boostQueue => ref.read(boostQueueProvider.notifier);

  RemoteCandleRepository get _repository => ref.read(candleRepositoryProvider);

  bool get _isActiveScreen => candleId == null;
}
