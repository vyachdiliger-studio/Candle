import "package:flutter/material.dart";

import "../../../../core/constants/app_colors.dart";
import "../../../../core/constants/sizes.dart";

class ProfileActionButton extends StatelessWidget {
  const ProfileActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool danger;

  static const labelStyle = TextStyle(
    fontSize: AppFontSizes.titleLarge,
    fontWeight: FontWeight.w600,
    letterSpacing: AppTypography.trackingWide,
  );

  double minimumWidth(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: DefaultTextStyle.of(context).style.merge(labelStyle),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width.ceilToDouble();
    painter.dispose();

    return width + Sizes.generous + Sizes.smallPlus + (Sizes.large + Sizes.hairline) * 2;
  }

  @override
  Widget build(BuildContext context) {
    final bg = danger ? AppColors.errorSurface : AppColors.controlSurface;
    final border = danger ? AppColors.errorOutline : AppColors.controlOutline;
    final fg = danger ? AppColors.error : AppColors.primary;

    return Opacity(
      opacity: onTap == null ? AppEffects.disabledOpacity : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.control),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: Sizes.medium,
            horizontal: Sizes.large,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadii.control),
            border: Border.all(color: border, width: Sizes.hairline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: Sizes.generous),
              const SizedBox(width: Sizes.smallPlus),
              Expanded(
                child: Text(
                  label,
                  style: labelStyle.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
