import "package:dart_scope_functions/dart_scope_functions.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rive/rive.dart";

import "../candle_rive_loader_provider.dart";

class CandleIconRive extends HookConsumerWidget {
  final double progress;
  final bool isBurning;
  final VoidCallback? onTap;
  final GestureTapUpCallback? onTapUp;

  const CandleIconRive({
    super.key,
    required this.progress,
    required this.isBurning,
    this.onTap,
    this.onTapUp,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(candleRiveFileProvider).value;

    // Building a controller off the already-loaded file is synchronous, so an
    // icon never passes through a loading state. RiveWidgetBuilder would run
    // the whole async load per widget instead, which is what made markers blink
    // as the map added and removed them.
    final controller = useMemoized(
      () => file?.let(
        (it) => RiveWidgetController(
          it,
          artboardSelector: ArtboardSelector.byIndex(0),
          stateMachineSelector: StateMachineSelector.byIndex(0),
        ),
      ),
      [file],
    );

    useEffect(() => controller?.dispose, [controller]);

    if (controller == null) return const SizedBox.shrink();

    // candle.riv is driven by state machine inputs; moving to Rive data binding
    // needs the asset to be re-exported, so the deprecated API stays for now.
    // ignore: deprecated_member_use
    controller.stateMachine.number("progress")?.value = progress;
    // ignore: deprecated_member_use
    controller.stateMachine.boolean("isBurning")?.value = isBurning;

    return GestureDetector(
      onTap: onTap,
      onTapUp: onTapUp,
      child: RiveWidget(controller: controller, fit: Fit.contain),
    );
  }
}
