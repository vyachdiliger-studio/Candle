import "dart:async";
import "dart:math";

import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:flutter_hooks/flutter_hooks.dart";

import "../../../../core/constants/app_colors.dart";
import "../../../../core/constants/sizes.dart";
import "../../../../core/platform/tap_haptics.dart";

class CandleTapSparks extends HookWidget {
  const CandleTapSparks({
    super.key,
    required this.onTap,
    required this.enabled,
    required this.builder,
  });

  final VoidCallback? onTap;
  final bool enabled;
  final Widget Function(GestureTapUpCallback? onTapUp) builder;

  @override
  Widget build(BuildContext context) {
    final vsync = useSingleTickerProvider();
    final sparks = useMemoized(() => _Sparks(vsync), [vsync]);
    useEffect(() => sparks.dispose, [sparks]);
    final haptics = useMemoized(TapHaptics.new);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        builder(
          onTap == null
              ? null
              : (details) {
                  if (enabled) {
                    sparks.emit(details.localPosition, reducedMotion: reducedMotion);
                    unawaited(haptics.lightImpact());
                  }
                  onTap!();
                },
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(child: CustomPaint(painter: _SparkPainter(sparks))),
          ),
        ),
      ],
    );
  }
}

class _Spark {
  const _Spark(this.origin, this.travel, this.size, this.born, this.phase, this.featured);
  final Offset origin;
  final Offset travel;
  final double size;
  final Duration born;
  final double phase;
  final bool featured;
}

class _Sparks extends ChangeNotifier {
  _Sparks(TickerProvider vsync) {
    _ticker = vsync.createTicker(_tick);
  }

  late final Ticker _ticker;
  final _random = Random();
  final particles = <_Spark>[];
  Duration elapsed = Duration.zero;

  void emit(Offset origin, {required bool reducedMotion}) {
    if (!_ticker.isActive) {
      elapsed = Duration.zero;
      _ticker.start();
    }
    const count = CandleSparkStyle.particlesPerTap;
    const limit = count * CandleSparkStyle.maxBursts;
    if (particles.length + count > limit) {
      particles.removeRange(0, particles.length + count - limit);
    }
    for (var i = 0; i < count; i++) {
      final travel = Offset(
        (i / (count - 1) * 2 - 1 + (_random.nextDouble() - 0.5) * 0.35) * CandleSparkStyle.spread,
        -CandleSparkStyle.rise * (0.45 + _random.nextDouble() * 0.55),
      );
      particles.add(
        _Spark(
          origin,
          reducedMotion ? Offset.zero : travel,
          0.65 + _random.nextDouble() * 0.35,
          elapsed,
          _random.nextDouble() * pi * 2,
          i == 0,
        ),
      );
    }
    notifyListeners();
  }

  void _tick(Duration time) {
    elapsed = time;
    particles.removeWhere((spark) => time - spark.born >= CandleSparkStyle.lifetime);
    notifyListeners();
    if (particles.isEmpty) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.sparks) : super(repaint: sparks);
  final _Sparks sparks;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final paint = Paint();
    for (final spark in sparks.particles) {
      final t =
          ((sparks.elapsed - spark.born).inMicroseconds / CandleSparkStyle.lifetime.inMicroseconds)
              .clamp(0.0, 1.0);
      final moving = spark.travel != Offset.zero;
      final drift = moving
          ? Offset(sin(t * pi * 2 + spark.phase) * sin(t * pi) * CandleSparkStyle.drift, 0)
          : Offset.zero;
      final position = spark.origin + spark.travel * Curves.easeOutQuad.transform(t) + drift;
      if (spark.featured && t < 0.35) {
        final flash = 1 - t / 0.35;
        final flashRadius = CandleSparkStyle.flashRadius * (0.65 + t);
        paint.shader = RadialGradient(
          colors: [
            AppColors.sparkCore.withValues(alpha: flash * 0.45),
            AppColors.sparkGlow.withValues(alpha: flash * 0.16),
            AppColors.sparkGlow.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: spark.origin, radius: flashRadius));
        canvas.drawCircle(spark.origin, flashRadius, paint);
        paint.shader = null;
      }
      final opacity = (1 - t) * (0.65 + 0.35 * pow(sin(t * pi * 3 + spark.phase), 2));
      final radius = CandleSparkStyle.radius * spark.size * (1 - t * 0.6);
      final glowRadius = CandleSparkStyle.glowRadius * spark.size;
      paint.shader = RadialGradient(
        colors: [
          AppColors.sparkGlow.withValues(alpha: opacity * 0.45),
          AppColors.sparkGlow.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: position, radius: glowRadius));
      canvas.drawCircle(position, glowRadius, paint);
      paint.shader = null;
      paint.color = AppColors.sparkCore.withValues(alpha: opacity);
      paint.strokeWidth = CandleSparkStyle.trailWidth * spark.size;
      paint.strokeCap = StrokeCap.round;
      if (spark.travel.distance > 0) {
        final trail = spark.travel / spark.travel.distance * CandleSparkStyle.trailLength * (1 - t);
        canvas.drawLine(position - trail, position, paint);
      }
      canvas.drawCircle(position, radius, paint);
      if (spark.size > 0.85) {
        final ray = CandleSparkStyle.starRadius * spark.size * (1 - t);
        final star = Path()
          ..moveTo(position.dx, position.dy - ray)
          ..lineTo(position.dx + radius * 0.45, position.dy - radius * 0.45)
          ..lineTo(position.dx + ray * 0.7, position.dy)
          ..lineTo(position.dx + radius * 0.45, position.dy + radius * 0.45)
          ..lineTo(position.dx, position.dy + ray)
          ..lineTo(position.dx - radius * 0.45, position.dy + radius * 0.45)
          ..lineTo(position.dx - ray * 0.7, position.dy)
          ..lineTo(position.dx - radius * 0.45, position.dy - radius * 0.45)
          ..close();
        canvas.drawPath(star, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SparkPainter oldDelegate) => oldDelegate.sparks != sparks;
}
