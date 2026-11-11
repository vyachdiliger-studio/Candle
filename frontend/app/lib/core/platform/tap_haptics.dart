import "package:flutter/foundation.dart";
import "package:flutter/services.dart";

import "telegram_mini_app.dart";

class TapHaptics {
  final _clock = Stopwatch()..start();
  Duration? _lastImpact;
  static const _minimumInterval = Duration(milliseconds: 70);

  Future<void> lightImpact() async {
    final now = _clock.elapsed;
    if (_lastImpact != null && now - _lastImpact! < _minimumInterval) return;
    _lastImpact = now;
    try {
      if (telegramTapHaptic()) return;
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        await HapticFeedback.lightImpact();
      }
    } catch (_) {
      // Haptics are optional; an unavailable device must not interrupt a tap.
    }
  }
}
