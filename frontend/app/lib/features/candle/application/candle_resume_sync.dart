import "dart:async";

import "package:flutter/widgets.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "candle_controller.dart";
import "candle_gallery_controller.dart";

part "candle_resume_sync.g.dart";

/// Re-syncs the candles when the app, or the Telegram Mini App around it,
/// comes back to the foreground. Flutter reports web page visibility as
/// lifecycle changes, so one listener covers all platforms.
@Riverpod(keepAlive: true)
void candleResumeSync(Ref ref) {
  const minGap = Duration(seconds: 5);
  DateTime? lastSync;
  final listener = AppLifecycleListener(
    onResume: () {
      final now = DateTime.now();
      if (lastSync != null && now.difference(lastSync!) < minGap) return;
      lastSync = now;
      final selectedId = ref.read(candleGalleryProvider).value?.selectedId;
      if (selectedId != null) {
        unawaited(ref.read(candleControllerProvider(selectedId).notifier).syncWithServer());
      }
      unawaited(ref.read(candleGalleryProvider.notifier).refreshQuietly());
    },
  );
  ref.onDispose(listener.dispose);
}
