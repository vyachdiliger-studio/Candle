import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../application/moderation_controller.dart";

class BlockAuthorDialog extends ConsumerWidget {
  const BlockAuthorDialog({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(moderationControllerProvider);
    return PopScope(
      canPop: !action.isLoading,
      child: AlertDialog(
        title: Text(context.l10n.blockAuthorQuestion),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.blockAuthorHelp),
            if (action.isLoading) const LinearProgressIndicator(),
            if (action.hasError) Text(context.l10n.blockFailed),
          ],
        ),
        actions: [
          TextButton(
            onPressed: action.isLoading ? null : () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: action.isLoading
                ? null
                : () async {
                    final blocked = await ref
                        .read(moderationControllerProvider.notifier)
                        .setBlocked(userId, blocked: true);
                    if (blocked && context.mounted) Navigator.of(context).pop(true);
                  },
            child: Text(context.l10n.block),
          ),
        ],
      ),
    );
  }
}
