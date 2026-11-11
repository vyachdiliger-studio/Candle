import "package:intl/intl.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "package:flutter/material.dart";

class CandleClusterBubble extends StatelessWidget {
  static const _accent = AppColors.primary;
  static const _ink = AppColors.surface;

  static const diameter = AppDimensions.clusterMarker;

  final int count;
  final VoidCallback? onTap;

  const CandleClusterBubble({super.key, required this.count, this.onTap});

  static String label(int count, {required String locale}) =>
      NumberFormat.compact(locale: locale).format(count);

  @override
  Widget build(BuildContext context) {
    final isSingle = count == 1;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSingle ? _ink : _accent,
              border: Border.all(color: isSingle ? _accent : _ink, width: Sizes.tiny),
            ),
            alignment: Alignment.center,
            child: isSingle
                ? const Icon(
                    Icons.local_fire_department,
                    color: _accent,
                    size: Sizes.comfortable,
                  )
                : Text(
                    label(count, locale: Localizations.localeOf(context).toLanguageTag()),
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: AppFontSizes.label,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
