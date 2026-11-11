import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "../../../../core/constants/sizes.dart";
import "../../../../core/location/location_controller.dart";
import "../../../../l10n/localization.dart";

class MapLocationButton extends ConsumerWidget {
  const MapLocationButton({super.key, required this.onLocate});
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(locationControllerProvider.select((value) => value.isLoading));
    return Positioned(
      top: Sizes.medium,
      right: Sizes.medium + AppDimensions.mapControl + Sizes.small,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        elevation: AppEffects.elevationFloating,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          tooltip: context.l10n.myLocation,
          onPressed: loading ? null : onLocate,
          icon: loading
              ? const SizedBox.square(
                  dimension: Sizes.generous,
                  child: CircularProgressIndicator(strokeWidth: AppStrokes.regular),
                )
              : const Icon(Icons.my_location),
        ),
      ),
    );
  }
}
