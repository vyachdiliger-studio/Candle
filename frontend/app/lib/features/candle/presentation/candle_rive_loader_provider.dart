import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:rive/rive.dart";

final candleRiveLoaderProvider = Provider((ref) {
  final loader = FileLoader.fromAsset(
    "assets/animations/candle.riv",
    riveFactory: Factory.flutter,
  );

  ref.onDispose(loader.dispose);

  return loader;
});

/// Loaded once for the whole app; every artboard is then instantiated from this
/// one file synchronously.
final candleRiveFileProvider = FutureProvider(
  (ref) => ref.watch(candleRiveLoaderProvider).file(),
);
