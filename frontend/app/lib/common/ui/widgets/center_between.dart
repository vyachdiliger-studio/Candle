import "package:candle_frontend/core/constants/sizes.dart";
import "package:flutter/material.dart";

class CenterBetween extends StatelessWidget {
  final Widget? left;
  final Widget? right;
  final Widget child;
  final CrossAxisAlignment crossAxisAlignment;

  const CenterBetween({
    super.key,
    this.left,
    this.right,
    required this.child,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: crossAxisAlignment,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AbsorbPointer(
            child: Opacity(
              opacity: 0,
              child: SizedBox(height: Sizes.none, child: right),
            ),
          ),
          Flexible(child: left ?? SizedBox.shrink()),
        ],
      ),
      Flexible(child: child),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AbsorbPointer(
            child: Opacity(
              opacity: 0,
              child: SizedBox(height: Sizes.none, child: left),
            ),
          ),
          Flexible(child: right ?? SizedBox.shrink()),
        ],
      ),
    ],
  );
}
