import "package:candle_frontend/core/constants/app_colors.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

import "../../domain/candle_comment.dart";

/// Text field at the bottom of the comments sheet. For guests it is replaced by
/// a sign-in button.
class CommentComposer extends HookWidget {
  const CommentComposer({
    super.key,
    required this.signedIn,
    required this.onSend,
    required this.onSignIn,
    this.replyTo,
    this.onCancelReply,
  });

  static const maxLength = 1000;

  /// The counter appears close to the limit only.
  static const counterFrom = 900;

  final bool signedIn;
  final CandleComment? replyTo;
  final VoidCallback? onCancelReply;

  /// Returns true when the comment was sent; the field is cleared then.
  final Future<bool> Function(String text) onSend;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = useTextEditingController();
    final focus = useFocusNode();
    final sending = useState(false);
    useListenable(text);

    useEffect(() {
      if (replyTo != null) focus.requestFocus();
      return null;
    }, [replyTo?.id]);

    if (!signedIn) {
      return Padding(
        padding: const EdgeInsets.all(Sizes.small),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey("comment-sign-in"),
            onPressed: onSignIn,
            icon: const Icon(Icons.login),
            label: Text(l10n.signInToComment),
          ),
        ),
      );
    }

    final canSend = !sending.value && text.text.trim().isNotEmpty;

    Future<void> send() async {
      if (!canSend) return;
      sending.value = true;
      final sent = await onSend(text.text.trim());
      if (!context.mounted) return;
      sending.value = false;
      if (sent) text.clear();
    }

    final reply = replyTo;
    final replyName = reply?.author?.username ?? "candle_${reply?.author?.id}";
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reply != null)
          Padding(
            padding: const EdgeInsets.only(left: Sizes.small, top: Sizes.extraSmall),
            child: InputChip(
              key: const ValueKey("comment-reply-chip"),
              label: Text(l10n.replyingTo(replyName)),
              onDeleted: onCancelReply,
              deleteButtonTooltipMessage: l10n.cancel,
              backgroundColor: AppColors.controlSurface,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Sizes.small,
            Sizes.extraSmall,
            Sizes.extraSmall,
            Sizes.small,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey("comment-field"),
                  controller: text,
                  focusNode: focus,
                  enabled: !sending.value,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: maxLength,
                  textInputAction: TextInputAction.newline,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                      currentLength < counterFrom ? null : Text("$currentLength/$maxLength"),
                  decoration: InputDecoration(
                    hintText: l10n.writeComment,
                    filled: true,
                    fillColor: AppColors.inputSurface,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.extraLarge),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              sending.value
                  ? const Padding(
                      padding: EdgeInsets.all(Sizes.regular),
                      child: SizedBox.square(
                        dimension: Sizes.comfortable,
                        child: CircularProgressIndicator(strokeWidth: AppStrokes.regular),
                      ),
                    )
                  : IconButton(
                      key: const ValueKey("comment-send"),
                      tooltip: l10n.sendComment,
                      onPressed: canSend ? send : null,
                      icon: const Icon(Icons.send),
                      color: AppColors.primary,
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
