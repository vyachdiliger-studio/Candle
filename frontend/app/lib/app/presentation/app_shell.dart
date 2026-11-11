import "package:candle_frontend/features/candle/presentation/widgets/candle_burn_hint_overlay.dart";
import "package:candle_frontend/common/ui/widgets/center_between.dart";
import "package:candle_frontend/features/candle/presentation/widgets/candle_countdown.dart";
import "/features/candle/presentation/widgets/background/candle_scene.dart";
import "package:candle_frontend/features/candle/application/candle_resume_sync.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:go_router/go_router.dart";

import "package:candle_frontend/core/constants/app_colors.dart";
import "package:candle_frontend/core/constants/sizes.dart";

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(candleResumeSyncProvider);
    return CandleScene(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppDimensions.candleContentMaxWidth),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    SizedBox(height: Sizes.medium),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Sizes.medium),
                      child: CenterBetween(
                        left: _MenuButton(onTap: Scaffold.of(context).openDrawer),
                        right: _IconButton(
                          icon: Icons.map_outlined,
                          onTap: () => context.pushNamed("map"),
                        ),
                        child: const CandleCountdown(),
                      ),
                    ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ),
          const CandleBurnHintOverlay(),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final void Function() onTap;

  const _MenuButton({required this.onTap});

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
          child: Icon(Icons.menu, color: AppColors.primary, size: Sizes.spacious),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const size = AppDimensions.mapControl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          child: Icon(icon, color: AppColors.primary, size: Sizes.generous),
        ),
      ),
    );
  }
}
