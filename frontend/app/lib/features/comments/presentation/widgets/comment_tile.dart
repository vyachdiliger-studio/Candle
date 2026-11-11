import "package:candle_frontend/core/constants/app_colors.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";

import "../../../user/presentation/widgets/user_avatar.dart";
import "../../domain/candle_comment.dart";
import "../comment_layout.dart";

enum CommentAction { delete, report }

/// One comment in the thread. [depth] is the indentation level inside the
/// current list; guide lines are drawn for every level above it, and from the
/// avatar down when [connectsDown] (its replies follow).
class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comment,
    required this.depth,
    required this.connectsDown,
    required this.now,
    required this.isCandleAuthor,
    required this.isOwn,
    required this.canInteract,
    this.expanded = false,
    this.onReply,
    this.onHideReplies,
    this.onAction,
  });

  final CandleComment comment;
  final int depth;
  final bool connectsDown;
  final DateTime now;
  final bool isCandleAuthor;
  final bool isOwn;

  /// Signed in: may reply and use the overflow menu.
  final bool canInteract;
  final bool expanded;
  final VoidCallback? onReply;
  final VoidCallback? onHideReplies;
  final ValueChanged<CommentAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final deleted = comment.isDeleted;
    final author = comment.author;
    final name = author == null ? "" : "@${author.username ?? "candle_${author.id}"}";

    return CustomPaint(
      painter: ThreadLinesPainter(depth: depth, connectsDown: connectsDown),
      child: Padding(
        padding: EdgeInsets.only(
          left: depth * CommentLayout.indent,
          top: Sizes.small,
          bottom: Sizes.extraSmall,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: deleted ? AppEffects.unavailableOpacity : 1,
              child: const UserAvatar(size: CommentLayout.avatar),
            ),
            const SizedBox(width: Sizes.small),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (!deleted) ...[
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (isCandleAuthor) ...[
                                const SizedBox(width: Sizes.extraSmall),
                                _AuthorBadge(label: l10n.commentAuthorBadge),
                              ],
                              const SizedBox(width: Sizes.compact),
                            ],
                            Text(
                              formatCommentAge(context, comment.createdAt, now),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: AppFontSizes.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (canInteract && !deleted && onAction != null)
                        _CommentMenu(isOwn: isOwn, onAction: onAction!),
                    ],
                  ),
                  if (deleted)
                    Text(
                      l10n.commentDeleted,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    SelectableText(comment.text ?? ""),
                  if ((canInteract && !deleted && onReply != null) || expanded)
                    Wrap(
                      children: [
                        if (canInteract && !deleted && onReply != null)
                          _SmallButton(label: l10n.reply, onPressed: onReply),
                        if (expanded && onHideReplies != null)
                          _SmallButton(label: l10n.hideReplies, onPressed: onHideReplies),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Show N replies", "Show more replies", "View thread" and the loading row,
/// placed at the depth of the replies they stand for.
class CommentBranchAction extends StatelessWidget {
  const CommentBranchAction({
    super.key,
    required this.depth,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  final int depth;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: ThreadLinesPainter(depth: depth, connectsDown: false, endsHere: true),
    child: Padding(
      padding: EdgeInsets.only(left: depth * CommentLayout.indent),
      child: Align(
        alignment: Alignment.centerLeft,
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(Sizes.small),
                child: SizedBox.square(
                  dimension: Sizes.medium,
                  child: CircularProgressIndicator(strokeWidth: AppStrokes.regular),
                ),
              )
            : _SmallButton(label: label, onPressed: onPressed, prefix: "— "),
      ),
    ),
  );
}

class ThreadLinesPainter extends CustomPainter {
  const ThreadLinesPainter({
    required this.depth,
    required this.connectsDown,
    this.endsHere = false,
  });

  final int depth;
  final bool connectsDown;

  /// The innermost line stops at the middle of this row (the branch ends here).
  final bool endsHere;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineMuted
      ..strokeWidth = AppStrokes.thin;
    for (var level = 0; level < depth; level++) {
      final x = level * CommentLayout.indent + CommentLayout.avatar / 2;
      final last = endsHere && level == depth - 1;
      canvas.drawLine(Offset(x, 0), Offset(x, last ? size.height / 2 : size.height), paint);
    }
    if (connectsDown) {
      final x = depth * CommentLayout.indent + CommentLayout.avatar / 2;
      const top = Sizes.small + CommentLayout.avatar + Sizes.extraSmall;
      canvas.drawLine(Offset(x, top), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(ThreadLinesPainter old) =>
      old.depth != depth || old.connectsDown != connectsDown || old.endsHere != endsHere;
}

class _AuthorBadge extends StatelessWidget {
  const _AuthorBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Sizes.compact, vertical: Sizes.tiny),
    decoration: BoxDecoration(
      color: AppColors.controlSurface,
      borderRadius: BorderRadius.circular(AppRadii.small),
    ),
    child: Text(
      label,
      style: const TextStyle(color: AppColors.primary, fontSize: AppFontSizes.mini),
    ),
  );
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, this.onPressed, this.prefix = ""});

  final String label;
  final VoidCallback? onPressed;
  final String prefix;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.extraSmall),
      minimumSize: const Size(Sizes.none, AppDimensions.actionHeight),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: AppColors.textSecondary,
      textStyle: const TextStyle(fontSize: AppFontSizes.label),
    ),
    child: Text("$prefix$label"),
  );
}

class _CommentMenu extends StatelessWidget {
  const _CommentMenu({required this.isOwn, required this.onAction});

  final bool isOwn;
  final ValueChanged<CommentAction> onAction;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: AppDimensions.actionHeight,
    child: PopupMenuButton<CommentAction>(
      tooltip: context.l10n.commentActions,
      padding: EdgeInsets.zero,
      iconSize: Sizes.comfortable,
      icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
      onSelected: onAction,
      itemBuilder: (_) => [
        if (isOwn)
          PopupMenuItem(value: CommentAction.delete, child: Text(context.l10n.deleteComment))
        else
          PopupMenuItem(value: CommentAction.report, child: Text(context.l10n.reportComment)),
      ],
    ),
  );
}
