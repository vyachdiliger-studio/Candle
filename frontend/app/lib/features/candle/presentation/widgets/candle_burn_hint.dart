import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

import "../../../../core/constants/app_colors.dart";

class CandleBurnHint extends HookWidget {
  const CandleBurnHint({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final animation = useAnimationController(duration: const Duration(milliseconds: 1600));
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    useEffect(() {
      if (active) {
        animation.forward(from: 0);
      } else {
        animation.reset();
      }
      return null;
    }, [active]);

    if (!active) return const SizedBox.shrink();

    return IgnorePointer(
      child: ExcludeSemantics(
        child: ClipRect(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final entry = const Interval(
                0,
                0.25,
                curve: Curves.easeOutCubic,
              ).transform(animation.value);
              final exit = const Interval(
                0.65,
                1,
                curve: Curves.easeInCubic,
              ).transform(animation.value);
              final opacity = entry * (1 - exit);
              final scale = reduceMotion
                  ? 1.0
                  : AppEffects.hintInitialScale +
                        entry * AppEffects.hintScaleGrowth +
                        exit * AppEffects.hintExitGrowth;

              return Center(
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(scale: scale, child: child),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Sizes.generous),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  context.l10n.burnHint,
                  style: TextStyle(
                    fontSize: AppFontSizes.hint,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    shadows: [
                      Shadow(
                        color: AppColors.hintShadow,
                        blurRadius: Sizes.medium,
                        offset: Offset(Sizes.none, Sizes.tiny),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
