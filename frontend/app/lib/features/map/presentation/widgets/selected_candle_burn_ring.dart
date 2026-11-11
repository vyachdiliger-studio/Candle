import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "dart:math" as math;
import "package:flutter/material.dart";

class SelectedCandleBurnRing extends StatelessWidget {
  const SelectedCandleBurnRing({
    super.key,
    required this.burnProgress, // 0..1 (1 = осталось 100%)
    this.innerDiameter = AppDimensions.burnRingDiameter,
    this.strokeWidth = AppStrokes.burnRing,
    this.remainingColor = AppColors.burnRemaining,
    this.burnedColor = AppColors.burnElapsed,

    // аура
    this.glowStrength = AppEffects.burnGlowStrength, // 1.3..2.4
    this.glowTint = AppColors.burnGlow,
    this.glowTintMix = AppEffects.burnGlowTintMix, // 0..1
    this.glowUnderStrength = AppEffects.burnGlowUnderStrength, // 0.0..1.0 (контраст на белом)
    // выразительность кольца
    this.coreStrength = AppEffects.burnCoreStrength, // 1.0..1.8
  });

  final double burnProgress;
  final double innerDiameter;
  final double strokeWidth;
  final Color remainingColor;
  final Color burnedColor;

  final double glowStrength;
  final Color glowTint;
  final double glowTintMix;
  final double glowUnderStrength;

  final double coreStrength;

  @override
  Widget build(BuildContext context) {
    final p = burnProgress.clamp(0.0, 1.0);
    final outerDiameter = innerDiameter + strokeWidth * 2;

    return SizedBox(
      width: outerDiameter,
      height: outerDiameter,
      child: CustomPaint(
        painter: _BurnRingPainter(
          remaining: p,
          strokeWidth: strokeWidth,
          remainingColor: remainingColor,
          burnedColor: burnedColor,
          glowStrength: glowStrength,
          glowTint: glowTint,
          glowTintMix: glowTintMix,
          glowUnderStrength: glowUnderStrength,
          coreStrength: coreStrength,
        ),
      ),
    );
  }
}

class _BurnRingPainter extends CustomPainter {
  _BurnRingPainter({
    required this.remaining,
    required this.strokeWidth,
    required this.remainingColor,
    required this.burnedColor,
    required this.glowStrength,
    required this.glowTint,
    required this.glowTintMix,
    required this.glowUnderStrength,
    required this.coreStrength,
  });

  final double remaining; // 0..1
  final double strokeWidth;
  final Color remainingColor;
  final Color burnedColor;

  final double glowStrength;
  final Color glowTint;
  final double glowTintMix;
  final double glowUnderStrength;

  final double coreStrength;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const startAngle = -math.pi / 2;
    final sweepRemaining = math.pi * 2 * remaining;

    double a(double x) => x.clamp(0.0, 1.0);

    // 1) аура вокруг ВСЕЙ окружности: подложка (видно на белом) + свет (красиво на тёмном)
    final glowBase = Color.lerp(remainingColor, glowTint, glowTintMix)!;

    for (final layer in AppEffects.burnGlowLayers) {
      // A) тёмная подложка (контраст на светлом фоне)
      final under = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + layer.extraWidth
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.multiply
        ..color = AppColors.shadow.withValues(
          alpha: a(layer.alpha * glowUnderStrength * glowStrength),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, layer.blur);

      canvas.drawArc(rect, startAngle, math.pi * 2, false, under);

      // B) светящийся слой (не делает серую окантовку)
      final over = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + layer.extraWidth
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus
        ..color = glowBase.withValues(alpha: a(layer.alpha * glowStrength))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, layer.blur);

      canvas.drawArc(rect, startAngle, math.pi * 2, false, over);
    }

    // 2) "сгоревшая" часть: полный круг серым
    final burnedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..color = burnedColor.withValues(alpha: a(AppEffects.burnElapsedAlpha * coreStrength));
    canvas.drawArc(rect, 0, math.pi * 2, false, burnedPaint);

    // 3) "оставшаяся" часть: жёлтая дуга поверх серого
    if (sweepRemaining > 0) {
      final remainingPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = remainingColor.withValues(alpha: a(AppEffects.burnRemainingAlpha * coreStrength));
      canvas.drawArc(rect, startAngle, sweepRemaining, false, remainingPaint);
    }

    // 4) тонкая “жилка” для читаемости
    final innerStroke = math.max(
      AppEffects.burnCoreMinimumWidth,
      strokeWidth * AppEffects.burnCoreWidthRatio,
    );

    final crispGray = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerStroke
      ..strokeCap = StrokeCap.butt
      ..color = burnedColor.withValues(alpha: a(1.0 * coreStrength));
    canvas.drawArc(rect, 0, math.pi * 2, false, crispGray);

    if (sweepRemaining > 0) {
      final crispYellow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = innerStroke
        ..strokeCap = StrokeCap.round
        ..color = remainingColor.withValues(alpha: a(1.0 * coreStrength));
      canvas.drawArc(rect, startAngle, sweepRemaining, false, crispYellow);
    }
  }

  @override
  bool shouldRepaint(covariant _BurnRingPainter old) {
    return old.remaining != remaining ||
        old.strokeWidth != strokeWidth ||
        old.remainingColor != remainingColor ||
        old.burnedColor != burnedColor ||
        old.glowStrength != glowStrength ||
        old.glowTint != glowTint ||
        old.glowTintMix != glowTintMix ||
        old.glowUnderStrength != glowUnderStrength ||
        old.coreStrength != coreStrength;
  }
}
