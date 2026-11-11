import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "package:flutter/material.dart";

class UserAvatar extends StatelessWidget {
  final double size;

  const UserAvatar({super.key, this.size = AppDimensions.avatar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.controlSurface,
        border: Border.all(
          color: AppColors.controlOutline,
          width: Sizes.hairline,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_outline,
          color: AppColors.primary,
          size: size * AppDimensions.avatarIconRatio,
        ),
      ),
    );
  }
}
