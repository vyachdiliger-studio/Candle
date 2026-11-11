import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";

class MapCompassButton extends StatelessWidget {
  const MapCompassButton({super.key});

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return Positioned(
      top: Sizes.medium,
      right: Sizes.medium,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        elevation: AppEffects.elevationFloating,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          tooltip: context.l10n.northUp,
          onPressed: () => MapController.of(context).rotate(0),
          icon: Transform.rotate(
            angle: camera.rotationRad,
            child: const Icon(Icons.navigation, color: AppColors.compassNeedle),
          ),
        ),
      ),
    );
  }
}
