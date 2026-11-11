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
    final duration = formatCandleDuration(remaining, context.l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.small),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(duration, style: const TextStyle(fontSize: AppFontSizes.titleLarge)),
      ),
    );
  }
}
