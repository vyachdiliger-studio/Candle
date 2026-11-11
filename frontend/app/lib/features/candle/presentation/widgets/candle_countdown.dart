import "package:candle_frontend/l10n/localization.dart";
import "../format_candle_duration.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../application/candle_controller.dart";
import "../../application/candle_gallery_controller.dart";

class CandleCountdown extends HookConsumerWidget {
  const CandleCountdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(
      candleGalleryProvider.select((value) => value.value?.selectedId),
    );
    final candle = selectedId == null
        ? null
        : ref.watch(candleControllerProvider(selectedId).select((value) => value.value?.candle));
    final timer = useMemoized(() => Stream.periodic(const Duration(seconds: 1)));
    useStream(timer);

    if (candle == null) return const SizedBox.shrink();

    final remaining = candle.extinguishedAt.difference(DateTime.now());
    return CandleCountdownDisplay(remaining: remaining);
  }
}

/// Presentation only; the controller remains the source of the burn deadline.
class CandleCountdownDisplay extends StatelessWidget {
  const CandleCountdownDisplay({super.key, required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final duration = formatCandleDuration(remaining);
    final l10n = context.l10n;
    final units = [
      (duration.days, l10n.countdownDays),
      (duration.hours, l10n.countdownHours),
      (duration.minutes, l10n.countdownMinutes),
      (duration.seconds, l10n.countdownSeconds),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.small),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < units.length; i++) ...[
              if (i > 0) const SizedBox(width: Sizes.small),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DefaultTextStyle.merge(
                    style: const TextStyle(
                      fontSize: AppFontSizes.titleLarge,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Reserve digit slots so ticking never shifts the columns.
                        ExcludeSemantics(
                          child: Opacity(
                            opacity: 0,
                            child: Text("8" * (i == 0 ? duration.days.length : 2)),
                          ),
                        ),
                        Text(units[i].$1),
                      ],
                    ),
                  ),
                  Text(units[i].$2, style: const TextStyle(fontSize: AppFontSizes.caption)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
