import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/common/hooks/use_frame_ticker.dart";
import "package:candle_frontend/features/candle/candle.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "candle_marker_badge.dart";
import "selected_candle_burn_ring.dart";

class CandleMapMarker extends HookConsumerWidget {
  static const diameter = AppDimensions.mapMarker;

  static const _outerPadding = Sizes.small;
  static const _innerPadding = Sizes.smallPlus;

  /// Distance from the bottom of the marker to the foot of the candle: the
  /// artboard is letterboxed by [Fit.contain] into what the paddings leave, and
  /// being taller than it is wide it fills that box vertically.
  static const _candleFoot = _outerPadding + _innerPadding;

  const CandleMapMarker({
    super.key,
    this.candle,
    this.count = 1,
    this.hasOwnCandle = false,
    required this.isSelected,
    this.onTap,
  });

  final Candle? candle;
  final int count;
  final bool hasOwnCandle;
  final bool isSelected;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candle = this.candle;

    // The tile endpoint knows only where a candle is, not how far it has burnt,
    // so the ring can only be drawn for the one candle we have fetched in full.
    final presNow = candle == null
        ? null
        : CandlePres.fromDomain(candle: candle, now: DateTime.now());

    final frame = useFrameTicker(
      enabled: isSelected && (presNow?.isBurning ?? false),
    );

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(_outerPadding),
              child: Padding(
                padding: const EdgeInsets.all(_innerPadding),
                child: CandleIconRive(progress: 1, isBurning: true),
              ),
            ),
            // Decorations must never compete with the marker's single tap action.
            if (isSelected && candle != null)
              IgnorePointer(
                child: Center(
                  child: ValueListenableBuilder(
                    valueListenable: frame,
                    builder: (context, _, _) {
                      final pres = CandlePres.fromDomain(
                        candle: candle,
                        now: DateTime.now(),
                      );

                      return SelectedCandleBurnRing(
                        burnProgress: pres.burnProgress,
                      );
                    },
                  ),
                ),
              ),
            if (count > 1 || hasOwnCandle)
              Positioned(
                left: Sizes.none,
                right: Sizes.none,
                bottom: Sizes.none,
                // Centre on the candle's foot without translating outside the
                // layout box. Bound large-text cluster labels to the tap target.
                height: _candleFoot * 2,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: CandleMarkerBadge(
                      count: count,
                      hasOwnCandle: hasOwnCandle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
