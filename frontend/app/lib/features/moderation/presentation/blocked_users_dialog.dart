import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../application/moderation_controller.dart";

class BlockedUsersDialog extends ConsumerWidget {
  const BlockedUsersDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(blockedUsersProvider);
    final action = ref.watch(moderationControllerProvider);
    return AlertDialog(
      title: Text(context.l10n.blockedAuthors),
      content: SizedBox(
        width: AppDimensions.dialogCompact,
        child: users.when(
          loading: () => const Center(heightFactor: 2, child: CircularProgressIndicator()),
          error: (_, _) => TextButton(
            onPressed: () => ref.invalidate(blockedUsersProvider),
            child: Text(context.l10n.blockedAuthorsFailed),
          ),
          data: (items) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (items.isEmpty) Text(context.l10n.noBlockedAuthors),
                for (final user in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("@${user.username}"),
                    trailing: TextButton(
                      onPressed: action.isLoading
                          ? null
                          : () => ref
                                .read(moderationControllerProvider.notifier)
                                .setBlocked(user.id, blocked: false),
                      child: Text(context.l10n.unblock),
                    ),
                  ),
                if (action.isLoading) const LinearProgressIndicator(),
                if (action.hasError) Text(context.l10n.unblockFailed),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.l10n.close)),
      ],
    );
  }
}
