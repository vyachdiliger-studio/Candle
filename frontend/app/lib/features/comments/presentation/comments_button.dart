import "package:candle_frontend/core/constants/app_colors.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";

/// TikTok-style comments button: an icon with the count under it, next to the
/// candle's support count.
class CommentsButton extends StatelessWidget {
  const CommentsButton({super.key, required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = NumberFormat.compact(locale: context.l10n.localeName).format(count);
    return Tooltip(
      message: context.l10n.commentsCount(count),
      child: InkResponse(
        key: const ValueKey("open-comments"),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(Sizes.small),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: Sizes.large),
              const SizedBox(height: Sizes.extraSmall),
              Text(
                label,
                style: const TextStyle(color: AppColors.primary, fontSize: AppFontSizes.small),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
