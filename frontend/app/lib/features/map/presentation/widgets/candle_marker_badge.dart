import "package:candle_frontend/core/constants/app_colors.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:flutter/material.dart";

import "candle_cluster_bubble.dart";

class CandleMarkerBadge extends StatelessWidget {
  const CandleMarkerBadge({
    super.key,
    required this.count,
    required this.hasOwnCandle,
  });

  final int count;
  final bool hasOwnCandle;

  @override
  Widget build(BuildContext context) {
    final isCluster = count > 1;
    final foreground = hasOwnCandle ? AppColors.primary : AppColors.surface;
    final background = hasOwnCandle ? AppColors.surface : AppColors.primary;

    return Container(
      constraints: const BoxConstraints(
        minWidth: Sizes.spacious,
        minHeight: Sizes.spacious,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isCluster ? Sizes.compact : Sizes.extraSmall,
        vertical: Sizes.tiny,
      ),
      decoration: BoxDecoration(
        color: background,
        shape: isCluster ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isCluster ? BorderRadius.circular(AppRadii.medium) : null,
        border: Border.all(color: foreground, width: AppStrokes.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasOwnCandle) Icon(Icons.person, color: foreground, size: Sizes.medium),
          if (hasOwnCandle && isCluster) const SizedBox(width: Sizes.extraSmall),
          if (isCluster)
            Text(
              CandleClusterBubble.label(
                count,
                locale: Localizations.localeOf(context).toLanguageTag(),
              ),
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: AppFontSizes.caption,
                height: AppTypography.leadingCompact,
              ),
            ),
        ],
      ),
    );
  }
}
