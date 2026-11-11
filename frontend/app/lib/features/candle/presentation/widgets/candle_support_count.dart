import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/l10n/localization.dart";

class CandleSupportCount extends StatelessWidget {
  const CandleSupportCount({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = NumberFormat.compact(locale: context.l10n.localeName).format(count);
    return Tooltip(
      message: context.l10n.candleSupporters(count),
      triggerMode: TooltipTriggerMode.tap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sizes.small, vertical: Sizes.small),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department, color: AppColors.primary, size: Sizes.large),
            const SizedBox(height: Sizes.extraSmall),
            Text(
              label,
              style: const TextStyle(color: AppColors.primary, fontSize: AppFontSizes.small),
            ),
          ],
        ),
      ),
    );
  }
}
