import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "package:flutter/material.dart";
import "background_editor_sheet.dart";

class BackgroundButton extends StatelessWidget {
  const BackgroundButton({super.key, required this.candleId});
  final int? candleId;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    icon: const Icon(Icons.wallpaper_outlined, size: Sizes.mediumPlus),
    label: Text(context.l10n.background),
    onPressed: () => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (_) => BackgroundEditorSheet(candleId: candleId),
    ),
  );
}
