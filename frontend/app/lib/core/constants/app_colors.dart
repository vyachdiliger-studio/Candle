import "package:flutter/painting.dart";

abstract final class AppColors {
  static const sparkCore = Color(0xFFFFF3C4);
  static const sparkGlow = Color(0xFFFFC65A);
  static const surface = Color(0xFF12181E);
  static const surfaceRaised = Color(0xFF1B222A);
  static const primary = Color(0xFFFFEDBC);
  static const onPrimary = Color(0xFF000000);
  static const textPrimary = primary;
  static const textSecondary = Color(0xCCFFEDBC);
  static const textMuted = Color(0x99FFFFFF);
  static const textSubtle = Color(0x8AFFFFFF);
  static const textBody = Color(0xB3FFFFFF);
  static const outlineMuted = Color(0x3DFFFFFF);
  static const error = Color(0xFFFF5252);
  static const destructive = Color(0xFFF44336);
  static const compassNeedle = error;
  static const telegramSurface = Color(0xFF229ED9);
  static const onTelegram = Color(0xFFFFFFFF);
  static const transparent = Color(0x00000000);
  static const shadow = Color(0xFF000000);
  static const hintShadow = Color(0xDD000000);
  static const candlePlaceholder = Color(0xFFFFDE9E);
  static const candleAmbient = Color(0xFF302A27);
  static const thumbnailScrimTop = Color(0x660B1016);
  static const thumbnailScrimCenter = Color(0x550B1016);
  static const thumbnailScrimBottom = Color(0xE60B1016);
  static const sceneScrimTop = Color(0xE612181E);
  static const sceneScrimCenter = Color(0x7012181E);
  static const sceneScrimLower = Color(0xA612181E);
  static const burnRemaining = Color(0xFFE29242);
  static const burnElapsed = Color(0xFF888987);
  static const burnGlow = Color(0xFFB79F2E);

  static final actionDisabled = primary.withValues(alpha: 0.25);
  static final actionForeground = primary.withValues(alpha: 0.85);

  static final controlSurface = primary.withValues(alpha: 0.14);
  static final navigationSurface = primary.withValues(alpha: 0.12);
  static final controlOutline = primary.withValues(alpha: 0.18);
  static final inputSurface = primary.withValues(alpha: 0.10);
  static final inputHint = primary.withValues(alpha: 0.6);
  static final messageHint = primary.withValues(alpha: 0.35);
  static final textPlaceholder = primary.withValues(alpha: 0.45);
  static final textCaption = primary.withValues(alpha: 0.70);
  static final locationText = primary.withValues(alpha: 0.75);
  static final pendingText = primary.withValues(alpha: 0.55);
  static final inputUnderline = primary.withValues(alpha: 0.25);
  static final errorSurface = error.withValues(alpha: 0.14);
  static final errorOutline = error.withValues(alpha: 0.28);
  static final cardSurface = surface.withValues(alpha: 0.92);
  static final cardShadow = shadow.withValues(alpha: 0.45);
}
