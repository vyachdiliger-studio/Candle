import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../application/candle_controller.dart";
import "../../../application/candle_gallery_controller.dart";
import "candle_backdrop.dart";

class CandleScene extends ConsumerWidget {
  const CandleScene({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(candleGalleryProvider.select((value) => value.value?.selectedId));
    final background = ref.watch(
      candleControllerProvider(id).select(
        (value) => value.value?.candle?.background ?? value.value?.draftBackground,
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        CandleBackdrop(resource: background),
        child,
      ],
    );
  }
}
