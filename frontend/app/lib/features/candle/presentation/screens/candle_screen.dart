import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "../widgets/background/background_button.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../application/candle_controller.dart";
import "../../application/candle_gallery_controller.dart";
import "../widgets/candle_actions.dart";
import "../models/candle_pres.dart";
import "../widgets/candle_rive_icon.dart";
import "../widgets/candle_support_count.dart";
import "../widgets/candle_tap_sparks.dart";
import "../../../comments/presentation/comments_button.dart";
import "../../../comments/presentation/comments_sheet.dart";

const _messageStyle = TextStyle(fontSize: AppFontSizes.candleTitle);

final _messageHintStyle = TextStyle(
  color: AppColors.messageHint,
  fontStyle: FontStyle.italic,
);

class CandleScreen extends HookConsumerWidget {
  final int? candleId;
  const CandleScreen({super.key, this.candleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(candleControllerProvider(candleId));
    final controller = ref.read(candleControllerProvider(candleId).notifier);
    final text = useTextEditingController(
      text: state.value?.candle?.message ?? state.value?.message ?? "",
    );
    final lighting = useState(false);
    final editingMessage = useState(false);
    final savingMessage = useState(false);
    final timer = useMemoized(() => Stream.periodic(const Duration(seconds: 1)));
    useStream(timer);
    final userId = ref.watch(galleryUserIdProvider);
    useEffect(() {
      final value = state.value;
      if (value != null && !editingMessage.value && !lighting.value) {
        final message = value.candle?.message ?? value.message;
        if (text.text != message) {
          text.value = TextEditingValue(
            text: message,
            selection: TextSelection.collapsed(offset: message.length),
          );
        }
      }
      return null;
    }, [state.value?.candle?.id, state.value?.candle?.message, editingMessage.value]);

    Future<void> tap() async {
      if (lighting.value) return;
      if (userId == null) {
        context.push(
          "/login?from=${Uri.encodeComponent(candleId == null ? "/" : "/candles/$candleId")}",
        );
        return;
      }
      lighting.value = true;
      try {
        await controller.onTap();
        if (context.mounted && candleId == null) {
          final selected = ref.read(candleGalleryProvider).value?.selectedId;
          text.clear();
          if (selected != null) context.replace("/candles/$selected");
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.lightFailed)));
        }
      } finally {
        if (context.mounted) lighting.value = false;
      }
    }

    Future<void> saveMessage() async {
      if (savingMessage.value) return;

      savingMessage.value = true;
      try {
        await controller.saveMessage();
        if (!context.mounted) return;
        editingMessage.value = false;
        FocusScope.of(context).unfocus();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.messageSaveFailed)));
        }
      } finally {
        if (context.mounted) savingMessage.value = false;
      }
    }

    void cancelMessage() {
      controller.cancelMessageEditing();
      final saved = state.value?.candle?.message ?? "";
      text.value = TextEditingValue(
        text: saved,
        selection: TextSelection.collapsed(offset: saved.length),
      );
      editingMessage.value = false;
      FocusScope.of(context).unfocus();
    }

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: TextButton(onPressed: controller.refresh, child: Text(context.l10n.retryCandle)),
      ),
      data: (data) {
        final candle = data.candle;
        final now = DateTime.now();
        final pres = candle == null ? null : CandlePres.fromDomain(candle: candle, now: now);
        final burning = pres?.isBurning ?? false;
        final owned = candle != null && userId != null && candle.author?.id == userId;
        return Column(
          children: [
            if (candle == null)
              TextField(
                key: const ValueKey("candle-draft-message"),
                style: _messageStyle,
                controller: text,
                enabled: !lighting.value,
                textAlign: TextAlign.center,
                maxLines: 1,
                textInputAction: TextInputAction.done,
                onChanged: controller.messageUpdated,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  hintText: context.l10n.messageHint,
                  hintStyle: _messageHintStyle,
                  border: InputBorder.none,
                ),
              )
            else if (owned && editingMessage.value)
              TextField(
                key: const ValueKey("candle-message-editor"),
                style: _messageStyle,
                controller: text,
                autofocus: true,
                enabled: !savingMessage.value,
                textAlign: TextAlign.center,
                maxLines: 1,
                textInputAction: TextInputAction.done,
                onChanged: controller.messageUpdated,
                onSubmitted: (_) async => saveMessage(),
                decoration: InputDecoration(
                  hintText: context.l10n.messageHint,
                  hintStyle: _messageHintStyle,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: const ValueKey("cancel-candle-message"),
                        tooltip: context.l10n.cancel,
                        onPressed: savingMessage.value ? null : cancelMessage,
                        icon: const Icon(Icons.close),
                      ),
                      savingMessage.value
                          ? const Padding(
                              padding: EdgeInsets.all(Sizes.regular),
                              child: SizedBox.square(
                                dimension: Sizes.comfortable,
                                child: CircularProgressIndicator(strokeWidth: AppStrokes.regular),
                              ),
                            )
                          : IconButton(
                              key: const ValueKey("save-candle-message"),
                              tooltip: context.l10n.save,
                              onPressed: saveMessage,
                              icon: const Icon(Icons.check),
                            ),
                    ],
                  ),
                ),
              )
            else if (owned)
              TextButton(
                key: const ValueKey("edit-candle-message"),
                onPressed: () => editingMessage.value = true,
                child: Text(
                  candle.message?.isNotEmpty == true ? candle.message! : context.l10n.addMessage,
                  style: _messageStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (!owned && candle?.message?.isNotEmpty == true)
              Text(
                candle!.message!,
                style: _messageStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            if (candle != null && !burning)
              Text(
                context.l10n.candleBurnedOut,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: AppFontSizes.title),
              ),
            const SizedBox(height: Sizes.medium),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CandleTapSparks(
                    enabled: userId != null && burning,
                    onTap: lighting.value || candle != null && !burning ? null : tap,
                    builder: (onTapUp) => CandleIconRive(
                      progress: pres?.burnProgress ?? 1,
                      isBurning: burning,
                      onTapUp: onTapUp,
                    ),
                  ),
                  if (candle != null)
                    Positioned(
                      right: Sizes.none,
                      bottom: Sizes.none,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CommentsButton(
                            count: candle.commentsCount,
                            onPressed: () => showCommentsSheet(
                              context,
                              candle: candle,
                              userId: userId,
                              onSignIn: () => context.push(
                                "/login?from=${Uri.encodeComponent("/candles/${candle.id}")}",
                              ),
                              onChanged: controller.syncWithServer,
                            ),
                          ),
                          CandleSupportCount(count: candle.supportersCount),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (lighting.value) const LinearProgressIndicator(),
            const SizedBox(height: Sizes.medium),
            if (candle == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (userId != null) ...[
                    BackgroundButton(candleId: candleId),
                    const SizedBox(width: Sizes.small),
                  ],
                  FilledButton.icon(
                    key: const ValueKey("light-candle"),
                    onPressed: lighting.value ? null : tap,
                    icon: const Icon(Icons.local_fire_department_outlined),
                    label: Text(context.l10n.light),
                  ),
                ],
              ),
            if (candle?.author != null)
              Text(
                "@${candle!.author!.username ?? "candle_${candle.author!.id}"}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            if (candle != null)
              CandleActions(candle: candle, owned: owned, canReport: userId != null),
          ],
        );
      },
    );
  }
}
