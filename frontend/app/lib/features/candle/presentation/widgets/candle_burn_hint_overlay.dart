import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../application/candle_controller.dart";
import "../../application/candle_gallery_controller.dart";
import "candle_burn_hint.dart";

class CandleBurnHintOverlay extends HookConsumerWidget {
  const CandleBurnHintOverlay({super.key});

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

    return CandleBurnHint(
      key: ValueKey(selectedId),
      active: candle != null && candle.extinguishedAt.isAfter(DateTime.now()),
    );
  }
}
