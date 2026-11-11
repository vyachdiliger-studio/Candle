import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "package:candle_frontend/common/utils/location_extension.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/core/models/location.dart";
import "package:flutter/material.dart";

class CandleLocationRow extends StatelessWidget {
  final Location? location;
  final String? address;
  final void Function()? onEdit;
  final void Function()? onShare;

  const CandleLocationRow({
    super.key,
    required this.location,
    this.address,
    this.onEdit,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final location = this.location;

    return Row(
      children: [
        Icon(
          Icons.place_outlined,
          size: Sizes.medium,
          color: AppColors.locationText,
        ),
        const SizedBox(width: Sizes.compact),
        Expanded(
          child: Text(
            address ?? location?.coordinatesLabel ?? context.l10n.notOnMap,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: location == null ? AppColors.textPlaceholder : AppColors.locationText,
              fontSize: AppFontSizes.label,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (onShare != null) _RowButton(icon: Icons.ios_share, onTap: onShare!),
        if (onEdit != null) _RowButton(icon: Icons.edit_location_alt_outlined, onTap: onEdit!),
      ],
    );
  }
}

class _RowButton extends StatelessWidget {
  final IconData icon;
  final void Function() onTap;

  const _RowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: Sizes.small),
        child: Icon(icon, size: Sizes.comfortable, color: AppColors.primary),
      ),
    );
  }
}
