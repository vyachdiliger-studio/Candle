abstract final class Sizes {
  static const double none = 0;
  static const double hairline = 1;
  static const double tiny = 2;
  static const double extraSmall = 4;
  static const double compact = 6;
  static const double small = 8;
  static const double smallPlus = 10;
  static const double regular = 12;
  static const double regularPlus = 14;
  static const double medium = 16;
  static const double mediumPlus = 18;
  static const double comfortable = 20;
  static const double generous = 24;
  static const double generousPlus = 26;
  static const double spacious = 28;
  static const double large = 32;
  static const double extraLarge = 64;
  static const double mega = 128;
  static const double extraMega = 256;
  static const defaultSize = none;
  static const extraTiny = hairline;
}

abstract final class AppDimensions {
  static const double candleContentMaxWidth = 600;
  static const double extraComfortable = 40;
  static const double mapControl = 46;
  static const double navigationControl = 52;
  static const double avatarCompact = 72;
  static const double mapMarker = 88;
  static const double candleThumbnail = 104;
  static const double avatar = 120;
  static const double candleGallery = 150;
  static const double backgroundPreview = 220;
  static const double dialogCompact = 360;
  static const double dialog = 400;
  static const double clusterMarker = 44;
  static const double actionHeight = 36;
  static const double burnRingDiameter = 52;
  static const double providerButtonWidth = 220;
  static const double thumbnailStride = candleThumbnail + Sizes.extraSmall * 2;
  static const double scrollTolerance = 1;
  static const double avatarIconRatio = 0.53;
}

abstract final class AppFontSizes {
  static const double micro = 10;
  static const double mini = 11;
  static const double caption = 12;
  static const double label = 13;
  static const double small = 14;
  static const double legalBody = 14.5;
  static const double bodyCompact = 15;
  static const double body = 16;
  static const double subtitle = 17;
  static const double titleSmall = 18;
  static const double title = 20;
  static const double titleMedium = 22;
  static const double titleLarge = 24;
  static const double candleTitle = 26;
  static const double heading = 28;
  static const double hint = 30;
}

abstract final class AppRadii {
  static const double small = 4;
  static const double medium = 10;
  static const double large = 12;
  static const double control = 14;
  static const double extraLarge = 20;
  static const double sheet = 24;
}

abstract final class AppStrokes {
  static const double thin = 1;
  static const double focused = 1.2;
  static const double badge = 1.5;
  static const double regular = 2;
  static const double burnRing = 4;
}

abstract final class AppTypography {
  static const double tracking = 0.2;
  static const double trackingWide = 0.3;
  static const double leadingCompact = 1.2;
  static const double leadingRelaxed = 1.5;
}

abstract final class AppEffects {
  static const double elevationNone = 0;
  static const double elevationFloating = 3;
  static const double backdropRadius = 1.1;
  static const double backdropCenterY = -0.2;
  static const thumbnailStops = [0.0, 0.4, 1.0];
  static const sceneStops = [0.0, 0.3, 0.68, 1.0];
  static const double hintInitialScale = 0.25;
  static const double hintScaleGrowth = 0.75;
  static const double hintExitGrowth = 4;
  static const double burnGlowStrength = 1.9;
  static const double burnGlowTintMix = 0.60;
  static const double burnGlowUnderStrength = 0.55;
  static const double burnCoreStrength = 1.35;
  static const double burnCoreWidthRatio = 0.55;
  static const double burnCoreMinimumWidth = 1;
  static const double burnElapsedAlpha = 0.92;
  static const double burnRemainingAlpha = 0.98;
  static const burnGlowLayers = [
    (extraWidth: 18.0, alpha: 0.22, blur: 22.0),
    (extraWidth: 12.0, alpha: 0.30, blur: 14.0),
    (extraWidth: 7.0, alpha: 0.36, blur: 10.0),
  ];
  static const double disabledOpacity = 0.6;
  static const double unavailableOpacity = 0.4;
}

abstract final class CandleSparkStyle {
  static const lifetime = Duration(milliseconds: 720);
  static const particlesPerTap = 9;
  static const maxBursts = 12;
  static const spread = 60.0;
  static const rise = 92.0;
  static const radius = 2.4;
  static const glowRadius = 9.0;
  static const trailLength = 10.0;
  static const trailWidth = 1.4;
  static const flashRadius = 27.0;
  static const drift = 12.0;
  static const starRadius = 5.0;
}
