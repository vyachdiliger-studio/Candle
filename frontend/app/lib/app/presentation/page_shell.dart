import "package:candle_frontend/common/ui/widgets/center_between.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "package:candle_frontend/core/constants/app_colors.dart";
import "package:candle_frontend/core/constants/sizes.dart";

class PageShell extends StatelessWidget {
  const PageShell({super.key, required this.child, required this.title});

  final Widget child;
  final String title;

  static const accent = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Sizes.medium),
            child: CenterBetween(
              left: _BackButton(
                onTap: () async {
                  final router = GoRouter.of(context);
                  // Start at the active nested navigator so PopScope/onExit
                  // can handle editing or selection before leaving the page.
                  final handled = await router.routerDelegate.popRoute();
                  // A direct link has no previous route. The root redirect
                  // sends guests to login and signed-in users to their candles.
                  if (!handled && context.mounted) router.go("/");
                },
              ),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: accent,
                  fontSize: AppFontSizes.title,
                  fontWeight: FontWeight.w600,
                  letterSpacing: AppTypography.tracking,
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppDimensions.navigationControl,
        height: AppDimensions.navigationControl,
        decoration: BoxDecoration(
          color: AppColors.navigationSurface,
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(
            color: AppColors.controlOutline,
            width: Sizes.hairline,
          ),
        ),
        child: const Center(
          child: Icon(Icons.arrow_back, color: AppColors.primary, size: Sizes.generousPlus),
        ),
      ),
    );
  }
}
