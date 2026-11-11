import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../application/background_editor_controller.dart";
import "../../../application/background_editor_state.dart";
import "candle_backdrop.dart";

class BackgroundEditorSheet extends ConsumerWidget {
  const BackgroundEditorSheet({super.key, required this.candleId});
  final int? candleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = backgroundEditorControllerProvider(candleId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    ref.listen(provider.select((value) => value.saved), (_, saved) {
      if (saved) Navigator.of(context).pop();
    });
    final hasImage = state.preview != null || state.resource != null;
    final uploading = state.operation == BackgroundOperation.uploading;
    return PopScope(
      canPop: !state.busy || uploading,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Sizes.generous),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.backgroundTitle,
                      style: TextStyle(
                        fontSize: AppFontSizes.titleMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: state.busy && !uploading ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: Sizes.medium),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.extraLarge),
                child: SizedBox(
                  height: AppDimensions.backgroundPreview,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CandleBackdrop(resource: state.resource, preview: state.preview),
                      const Center(
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          size: AppDimensions.avatarCompact,
                          color: AppColors.candlePlaceholder,
                        ),
                      ),
                      Positioned(
                        bottom: Sizes.mediumPlus,
                        left: Sizes.medium,
                        right: Sizes.medium,
                        child: Text(
                          context.l10n.backgroundSubtitle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Sizes.medium),
              OutlinedButton.icon(
                onPressed: state.busy ? null : controller.pick,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(hasImage ? context.l10n.chooseAnotherImage : context.l10n.chooseImage),
              ),
              if (hasImage)
                TextButton.icon(
                  onPressed: state.busy ? null : controller.remove,
                  icon: const Icon(Icons.hide_image_outlined),
                  label: Text(context.l10n.defaultBackground),
                ),
              Text(
                context.l10n.backgroundHelp,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: AppFontSizes.caption),
              ),
              if (state.busy) ...[
                const SizedBox(height: Sizes.medium),
                LinearProgressIndicator(
                  value: uploading && state.progress < 1 ? state.progress : null,
                ),
                const SizedBox(height: Sizes.small),
                Text(
                  uploading
                      ? state.progress < 1
                            ? context.l10n.uploadProgress((state.progress * 100).round())
                            : context.l10n.preparingImage
                      : context.l10n.pleaseWait,
                  textAlign: TextAlign.center,
                ),
                if (uploading)
                  TextButton(
                    onPressed: controller.cancelUpload,
                    child: Text(context.l10n.cancelUpload),
                  ),
              ],
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: Sizes.regular),
                  child: Text(
                    context.l10n.failure(state.error!),
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              const SizedBox(height: Sizes.comfortable),
              FilledButton(
                onPressed: state.busy || !state.changed ? null : controller.save,
                child: Text(
                  candleId == null ? context.l10n.useBackground : context.l10n.saveBackground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
