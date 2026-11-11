import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/experimental/mutation.dart";

class ShareLinkDialog extends ConsumerWidget {
  ShareLinkDialog({super.key, required this.text});

  final String text;
  final _copy = Mutation<void>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copying = ref.watch(_copy);
    return AlertDialog(
      title: Text(context.l10n.shareCandle),
      content: SizedBox(
        width: AppDimensions.dialog,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.shareHelp),
              const SizedBox(height: Sizes.medium),
              SelectableText(text),
              if (copying is MutationError) ...[
                const SizedBox(height: Sizes.regular),
                Text(
                  context.l10n.copyFailed,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.close),
        ),
        FilledButton.icon(
          onPressed: copying is MutationPending
              ? null
              : () => _copy.run(ref, (_) => Clipboard.setData(ClipboardData(text: text))),
          icon: Icon(copying is MutationSuccess ? Icons.check : Icons.copy_outlined),
          label: Text(copying is MutationSuccess ? context.l10n.copied : context.l10n.copyMessage),
        ),
      ],
    );
  }
}
