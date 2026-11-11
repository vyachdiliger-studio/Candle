import "dart:async";

import "package:candle_frontend/features/candle/application/boost/queue.dart";
import "package:candle_frontend/features/candle/application/candle_controller.dart";
import "package:candle_frontend/features/candle/application/candle_gallery_controller.dart";
import "package:candle_frontend/features/candle/application/candle_resume_sync.dart";
import "package:candle_frontend/features/candle/application/gallery_preferences.dart";
import "package:candle_frontend/features/candle/data/dio_candle_repository.dart";
import "package:candle_frontend/features/candle/domain/models/candle.dart";
import "package:dartz/dartz.dart";
import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";

import "candle_gallery_test.dart" show MemoryPreferences, Repository, candle;

class SyncRepository extends Repository {
  int fetches = 0;
  int othersTaps = 0;
  Completer<void>? boostGate;
  Completer<void>? fetchGate;

  Candle _extend(Candle c, int seconds) =>
      c.copyWith(extinguishedAt: c.extinguishedAt.add(Duration(seconds: seconds)));

  @override
  Future<Either<Unit, Candle>> boost({required int id, required int taps}) async {
    await boostGate?.future;
    return right(candles[id] = _extend(candles[id]!, taps + othersTaps));
  }

  @override
  Future<Either<Unit, Candle>> getById(int id) async {
    fetches++;
    final snapshot = candles[id];
    await fetchGate?.future;
    return snapshot == null ? left(unit) : right(snapshot);
  }
}

void main() {
  late SyncRepository repository;
  late ProviderContainer container;
  final base = DateTime.now().toUtc().add(const Duration(minutes: 10));

  Candle burning(int id) => candle(id).copyWith(extinguishedAt: base);

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  Future<void> open(int id) async {
    await container.read(candleGalleryProvider.future);
    await container.read(candleControllerProvider(id).future);
    await settle();
  }

  DateTime extinguishedAt(int id) =>
      container.read(candleControllerProvider(id)).value!.candle!.extinguishedAt;

  setUp(() {
    repository = SyncRepository();
    repository.candles[1] = burning(1);
    container = ProviderContainer(
      overrides: [
        galleryUserIdProvider.overrideWithValue(42),
        candleRepositoryProvider.overrideWithValue(repository),
        galleryPreferencesProvider.overrideWithValue(MemoryPreferences()),
      ],
    );
  });
  tearDown(() => container.dispose());

  test("the server's answer to our taps brings in taps made by others", () async {
    await open(1);
    repository.othersTaps = 9;
    await container.read(candleControllerProvider(1).notifier).onTap();
    expect(extinguishedAt(1), base.add(const Duration(seconds: 1)));
    await container.read(boostQueueProvider.notifier).flush(1);
    expect(extinguishedAt(1), base.add(const Duration(seconds: 10)));
    expect(
      container.read(candleGalleryProvider).value!.selected!.extinguishedAt,
      base.add(const Duration(seconds: 10)),
    );
  });

  test("taps made while a batch is in flight stay on top of the answer", () async {
    await open(1);
    final controller = container.read(candleControllerProvider(1).notifier);
    repository.boostGate = Completer<void>();
    await controller.onTap();
    final sending = container.read(boostQueueProvider.notifier).flush(1);
    await controller.onTap();
    repository.boostGate!.complete();
    await sending;
    expect(extinguishedAt(1), base.add(const Duration(seconds: 2)));
    expect(container.read(boostQueueProvider.notifier).pendingOf(1), 1);
  });

  test("syncing picks up other people's taps and keeps unsent ones", () async {
    await open(1);
    repository.candles[1] = repository.candles[1]!.copyWith(
      extinguishedAt: base.add(const Duration(seconds: 30)),
    );
    final controller = container.read(candleControllerProvider(1).notifier);
    await controller.onTap();
    await controller.syncWithServer();
    expect(extinguishedAt(1), base.add(const Duration(seconds: 31)));
  });

  test("a fetch that started before our own boost was confirmed is dropped", () async {
    await open(1);
    final controller = container.read(candleControllerProvider(1).notifier);
    repository.fetchGate = Completer<void>();
    final syncing = controller.syncWithServer();
    await controller.onTap();
    repository.othersTaps = 4;
    await container.read(boostQueueProvider.notifier).flush(1);
    final confirmed = extinguishedAt(1);
    repository.fetchGate!.complete();
    await syncing;
    expect(extinguishedAt(1), confirmed);
  });

  test("an extinguished candle drops queued taps instead of retrying them", () async {
    await open(1);
    final controller = container.read(candleControllerProvider(1).notifier);
    await controller.onTap();
    repository.candles[1] = repository.candles[1]!.copyWith(
      extinguishedAt: DateTime.now().toUtc().subtract(const Duration(seconds: 5)),
    );
    await controller.syncWithServer();
    expect(container.read(boostQueueProvider.notifier).pendingOf(1), 0);
  });

  test("a quiet gallery refresh updates times in place and keeps the selection", () async {
    repository.candles[2] = burning(2);
    await open(1);
    final gallery = container.read(candleGalleryProvider.notifier);
    gallery.select(2, sync: false);
    repository.candles[1] = repository.candles[1]!.copyWith(
      extinguishedAt: base.add(const Duration(minutes: 5)),
    );
    final states = <bool>[];
    container.listen(candleGalleryProvider, (_, next) => states.add(next.isLoading));
    await gallery.refreshQuietly();
    final state = container.read(candleGalleryProvider).value!;
    expect(state.selectedId, 2);
    expect(
      state.candles.firstWhere((c) => c.id == 1).extinguishedAt,
      base.add(const Duration(minutes: 5)),
    );
    expect(states, isNot(contains(true)));
  });

  test("a quiet gallery refresh keeps the new candle tab selected", () async {
    await open(1);
    final gallery = container.read(candleGalleryProvider.notifier);
    gallery.select(null, sync: false);
    await gallery.refreshQuietly();
    expect(container.read(candleGalleryProvider).value!.selectedId, isNull);
    expect(container.read(candleGalleryProvider).value!.candles, isNotEmpty);
  });

  testWidgets("coming back to the foreground re-syncs the selected candle", (tester) async {
    await tester.runAsync(() async {
      await open(1);
      container.read(candleResumeSyncProvider);
      repository.candles[1] = repository.candles[1]!.copyWith(
        extinguishedAt: base.add(const Duration(seconds: 30)),
      );
      final before = repository.fetches;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle();
      expect(repository.fetches, greaterThan(before));
      expect(extinguishedAt(1), base.add(const Duration(seconds: 30)));
    });
  });
}
