import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "package:candle_frontend/common/hooks/use_frame_ticker.dart";
import "package:candle_frontend/features/candle/candle.dart";
import "package:flutter/material.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class CandlePreviewCard extends HookConsumerWidget {
  final void Function()? onTap;
  final Candle candle;
  final Widget? details;

  const CandlePreviewCard({
    super.key,
    required this.candle,
    this.onTap,
    this.details,
  });

  static const bg = AppColors.surface;
  static const accent = AppColors.primary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pres = CandlePres.fromDomain(candle: candle, now: DateTime.now());
    final frame = useFrameTicker(enabled: pres.isBurning);

    final title = _title(candle, context.l10n);
    final details = this.details;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          border: Border(
            top: BorderSide(color: AppColors.controlOutline, width: Sizes.hairline),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: Sizes.generousPlus,
              offset: const Offset(Sizes.none, -Sizes.smallPlus),
              color: AppColors.cardShadow,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              const SizedBox(width: Sizes.medium),
              Padding(
                padding: EdgeInsets.only(bottom: Sizes.small),
                child: SizedBox(
                  width: Sizes.spacious,
                  child: AspectRatio(
                    aspectRatio: 1 / 5,
                    child: ValueListenableBuilder(
                      valueListenable: frame,
                      builder: (context, _, _) {
                        final pres = CandlePres.fromDomain(
                          candle: candle,
                          now: DateTime.now(),
                        );

                        return CandleIconRive(
                          progress: pres.burnProgress,
                          isBurning: pres.isBurning,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Sizes.medium),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Sizes.medium),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.l10n.candle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textCaption,
                          fontSize: AppFontSizes.label,
                          fontWeight: FontWeight.w600,
                          letterSpacing: AppTypography.tracking,
                        ),
                      ),
                      const SizedBox(height: Sizes.extraSmall),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: accent,
                          fontSize: AppFontSizes.titleSmall,
                          fontWeight: FontWeight.w700,
                          letterSpacing: AppTypography.tracking,
                        ),
                      ),
                      if (details != null) ...[
                        const SizedBox(height: Sizes.small),
                        details,
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: Sizes.medium),
            ],
          ),
        ),
      ),
    );
  }

  String _title(Candle c, AppLocalizations l10n) {
    final msg = c.message;

    if (msg != null && msg.trim().isNotEmpty) return msg.trim();

    return l10n.candleNumber(c.id);
  }
}
