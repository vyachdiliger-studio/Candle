import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "package:candle_frontend/common/utils/location_extension.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/core/models/location.dart";
import "package:candle_frontend/features/geocoding/domain/models/address_suggestion.dart";
import "package:candle_frontend/features/map/application/address_field_controller.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "candle_preview_card.dart";

class CandleLocationEditor extends HookConsumerWidget {
  final ValueListenable<Location> location;
  final String? initialAddress;
  final bool isSaving;
  final void Function() onCancel;
  final void Function() onSave;
  final void Function(Location) onMoveTo;

  const CandleLocationEditor({
    super.key,
    required this.location,
    this.initialAddress,
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
    required this.onMoveTo,
  });

  static const _accent = AppColors.primary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController();

    final state = ref.watch(addressFieldControllerProvider);
    final controller = ref.read(addressFieldControllerProvider.notifier);

    useEffect(() {
      final address = initialAddress;

      if (address == null) return null;

      textController.text = address;

      // Providers can't change while the tree is building.
      Future.microtask(() => controller.startWith(address));

      return null;
    }, const []);

    void onPick(AddressSuggestion suggestion) {
      textController.text = suggestion.label;

      controller.suggestionPicked(suggestion.label);

      onMoveTo(suggestion.location);
    }

    Future<void> onRestore() async {
      final label = await controller.restoreFromCoordinates(location.value);

      if (label != null) textController.text = label;
    }

    void onClear() {
      textController.clear();

      controller.clear();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.my_location,
              size: Sizes.medium,
              color: AppColors.locationText,
            ),
            const SizedBox(width: Sizes.compact),
            Expanded(
              child: ValueListenableBuilder<Location>(
                valueListenable: location,
                builder: (context, location, _) => Text(
                  location.coordinatesLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.locationText,
                    fontSize: AppFontSizes.label,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Sizes.small),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                enabled: !isSaving,
                onChanged: (text) => controller.textChanged(text, near: location.value),
                style: TextStyle(
                  color: state.isSynced ? AppColors.textPrimary : AppColors.pendingText,
                  fontSize: AppFontSizes.small,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: context.l10n.address,
                  hintStyle: TextStyle(
                    color: AppColors.messageHint,
                    fontSize: AppFontSizes.small,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: Sizes.small),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.inputUnderline),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.inputHint),
                  ),
                ),
              ),
            ),
            if (state.isSearching || state.isResolving)
              const Padding(
                padding: EdgeInsets.only(left: Sizes.small),
                child: SizedBox(
                  width: Sizes.medium,
                  height: Sizes.medium,
                  child: CircularProgressIndicator(
                    strokeWidth: AppStrokes.regular,
                    color: _accent,
                  ),
                ),
              )
            else ...[
              _FieldButton(
                icon: Icons.sync,
                onTap: state.canRestore ? onRestore : null,
              ),
              _FieldButton(
                icon: Icons.close,
                onTap: state.canClear ? onClear : null,
              ),
            ],
          ],
        ),
        if (state.suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Sizes.extraSmall),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final suggestion in state.suggestions)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onPick(suggestion),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: Sizes.small,
                      ),
                      child: Text(
                        suggestion.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: AppFontSizes.label,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: Sizes.regular),
        Row(
          children: [
            TextButton(
              onPressed: isSaving ? null : onCancel,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textCaption,
                padding: const EdgeInsets.symmetric(horizontal: Sizes.regular),
                minimumSize: const Size(Sizes.none, AppDimensions.actionHeight),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(context.l10n.cancel),
            ),
            const Spacer(),
            FilledButton(
              onPressed: isSaving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: CandlePreviewCard.bg,
                padding: const EdgeInsets.symmetric(horizontal: Sizes.medium),
                minimumSize: const Size(Sizes.none, AppDimensions.actionHeight),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(context.l10n.placeHere),
            ),
          ],
        ),
      ],
    );
  }
}

class _FieldButton extends StatelessWidget {
  final IconData icon;
  final void Function()? onTap;

  const _FieldButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: Sizes.small),
        child: Icon(
          icon,
          size: Sizes.comfortable,
          color: onTap == null ? AppColors.actionDisabled : AppColors.actionForeground,
        ),
      ),
    );
  }
}
