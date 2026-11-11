import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "../../application/candle_controller.dart";
import "../../domain/models/candle.dart";
import "../models/candle_pres.dart";
import "candle_rive_icon.dart";
import "background/candle_backdrop.dart";

class CandleThumbnail extends HookConsumerWidget {
  final Candle? candle;
  final String group;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onClose;
  const CandleThumbnail({
    super.key,
    required this.candle,
    required this.group,
    required this.selected,
    required this.onTap,
    this.onClose,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = useMemoized(() => Stream.periodic(const Duration(seconds: 1)));
    useStream(timer);
    final c = candle;
    final background = c != null
        ? c.background
        : ref.watch(candleControllerProvider(null).select((value) => value.value?.draftBackground));
    final pres = c == null ? null : CandlePres.fromDomain(candle: c, now: DateTime.now());
    final burning = pres?.isBurning ?? false;
    final message = c?.message?.trim();
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: AppDimensions.candleThumbnail,
          margin: const EdgeInsets.all(Sizes.extraSmall),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.large),
            border: Border.all(
              color: selected ? Theme.of(context).colorScheme.primary : AppColors.outlineMuted,
              width: selected ? AppStrokes.regular : AppStrokes.thin,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.medium),
            child: Stack(
              children: [
                Positioned.fill(child: CandleBackdrop(resource: background, thumbnail: true)),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(Sizes.compact),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: onClose == null ? Sizes.none : Sizes.comfortable,
                          ),
                          child: Text(
                            group,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: AppFontSizes.micro),
                          ),
                        ),
                        Expanded(
                          child: c == null
                              ? const Icon(Icons.add, size: Sizes.large)
                              : CandleIconRive(
                                  progress: pres?.burnProgress ?? 0,
                                  isBurning: burning,
                                ),
                        ),
                        Text(
                          c == null
                              ? context.l10n.newCandle
                              : message != null && message.isNotEmpty
                              ? message
                              : context.l10n.candleNumber(c.id),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: AppFontSizes.mini),
                        ),
                        if (c != null)
                          Text(
                            "@${c.author?.username ?? "candle_${c.author?.id ?? c.id}"}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: AppFontSizes.micro,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (onClose != null)
                  Positioned(
                    top: Sizes.tiny,
                    right: Sizes.tiny,
                    child: Material(
                      color: AppColors.controlSurface,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: IconButton(
                        tooltip: context.l10n.closeRecentCandle,
                        onPressed: onClose,
                        padding: const EdgeInsets.all(Sizes.extraSmall),
                        constraints: const BoxConstraints.tightFor(
                          width: Sizes.large,
                          height: Sizes.large,
                        ),
                        icon: const Icon(Icons.close, size: Sizes.medium, color: AppColors.primary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
