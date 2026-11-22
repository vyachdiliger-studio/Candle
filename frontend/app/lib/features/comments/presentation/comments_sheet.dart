import "dart:async";

import "package:candle_frontend/core/constants/app_colors.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../candle/domain/models/candle.dart";
import "../../moderation/presentation/report_dialog.dart";
import "../application/comments_controller.dart";
import "../domain/candle_comment.dart";
import "comment_layout.dart";
import "widgets/comment_composer.dart";
import "widgets/comment_tile.dart";

/// Opens a candle's comments as a bottom sheet at two thirds of the screen.
Future<void> showCommentsSheet(
  BuildContext context, {
  required Candle candle,
  required int? userId,
  required VoidCallback onSignIn,
  VoidCallback? onChanged,
}) => showModalBottomSheet<void>(
  context: context,
  // The shell's navigator is as narrow as the candle column; the root one lets
  // the scrim cover the whole window while the sheet keeps the column width.
  useRootNavigator: true,
  constraints: const BoxConstraints(maxWidth: AppDimensions.candleContentMaxWidth),
  isScrollControlled: true,
  useSafeArea: true,
  // The header handles drags itself, so the list keeps pull-to-refresh.
  enableDrag: false,
  backgroundColor: AppColors.surfaceRaised,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
  ),
  builder: (_) => CommentsSheet(
    candle: candle,
    userId: userId,
    onSignIn: onSignIn,
    onChanged: onChanged,
  ),
);

class CommentsSheet extends HookConsumerWidget {
  const CommentsSheet({
    super.key,
    required this.candle,
    required this.userId,
    required this.onSignIn,
    this.onChanged,
  });

  final Candle candle;

  /// The signed-in user, or null for a guest.
  final int? userId;
  final VoidCallback onSignIn;

  /// Called after a comment was posted or deleted, e.g. to refresh the counter.
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = commentsControllerProvider(candle.id);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final l10n = context.l10n;

    final height = useAnimationController(initialValue: CommentLayout.sheetHeight);
    useAnimation(height);
    final focus = useState<List<int>>(const []);
    final replyTo = useState<CandleComment?>(null);
    final countDelta = useState(0);
    final messenger = useMemoized(GlobalKey<ScaffoldMessengerState>.new);

    useEffect(() {
      Future.microtask(controller.refresh);
      return null;
    }, const []);

    // A focused comment can disappear (deleted with nothing left below it).
    final focused = focus.value.isEmpty ? null : state.comments[focus.value.last];
    if (focus.value.isNotEmpty && focused == null && state.top.loaded) {
      Future.microtask(() => focus.value = const []);
    }

    void showMessage(String text) =>
        messenger.currentState?.showSnackBar(SnackBar(content: Text(text)));

    void openThread(CandleComment comment) {
      focus.value = [...focus.value, comment.id];
      unawaited(controller.showReplies(comment.id));
    }

    Future<bool> send(String text) async {
      final parent = replyTo.value;
      final result = await controller.post(text, parentCommentId: parent?.id);
      if (!context.mounted) return result == CommentPostResult.sent;
      switch (result) {
        case CommentPostResult.sent:
          replyTo.value = null;
          countDelta.value++;
          onChanged?.call();
        case CommentPostResult.invalidText:
          showMessage(l10n.commentTextInvalid(CommentComposer.maxLength));
        case CommentPostResult.failed:
          showMessage(l10n.commentSendFailed);
      }
      return result == CommentPostResult.sent;
    }

    Future<void> act(CandleComment comment, CommentAction action) async {
      if (action == CommentAction.report) {
        final sent = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => ReportDialog(commentId: comment.id),
        );
        if (sent == true) showMessage(l10n.reportReceived);
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.deleteComment),
          content: Text(
            comment.repliesCount > 0
                ? l10n.deleteCommentWithReplies(comment.repliesCount)
                : l10n.deleteCommentConfirm,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const ValueKey("confirm-delete-comment"),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      final deleted = await controller.delete(comment.id);
      if (!context.mounted) return;
      if (deleted) {
        // The reply target may have been in the deleted branch.
        final target = replyTo.value;
        if (target != null && !ref.read(provider).comments.containsKey(target.id)) {
          replyTo.value = null;
        }
        countDelta.value -= 1 + comment.repliesCount;
        onChanged?.call();
      } else {
        showMessage(l10n.commentDeleteFailed);
      }
    }

    final now = DateTime.now();
    final rows = <Widget>[];

    void addBranch(CandleComment comment, int depth) {
      final hasReplies = comment.repliesCount > 0;
      final expanded =
          hasReplies && state.isExpanded(comment.id) && depth < CommentLayout.maxInlineDepth;
      rows.add(
        CommentTile(
          key: ValueKey("comment-${comment.id}"),
          comment: comment,
          depth: depth,
          connectsDown: hasReplies,
          now: now,
          isCandleAuthor: comment.author != null && comment.author!.id == candle.author?.id,
          isOwn: userId != null && comment.author?.id == userId,
          canInteract: userId != null,
          // The focused comment of a branch view keeps its replies open.
          expanded: expanded && !(focused != null && depth == 0),
          onReply: () => replyTo.value = comment,
          onHideReplies: () => controller.hideReplies(comment.id),
          onAction: (action) => act(comment, action),
        ),
      );
      if (!hasReplies) return;
      final childDepth = depth + 1;
      if (depth >= CommentLayout.maxInlineDepth) {
        rows.add(
          CommentBranchAction(
            key: ValueKey("view-thread-${comment.id}"),
            depth: childDepth,
            label: l10n.viewThread,
            onPressed: () => openThread(comment),
          ),
        );
        return;
      }
      if (!expanded) {
        rows.add(
          CommentBranchAction(
            key: ValueKey("show-replies-${comment.id}"),
            depth: childDepth,
            label: l10n.showReplies(comment.repliesCount),
            onPressed: () => controller.showReplies(comment.id),
          ),
        );
        return;
      }
      for (final reply in state.repliesOf(comment.id)) {
        addBranch(reply, childDepth);
      }
      final list = state.repliesList(comment.id);
      if (list.loading) {
        rows.add(CommentBranchAction(depth: childDepth, label: "", loading: true));
      } else if (list.hasMore || list.failed) {
        rows.add(
          CommentBranchAction(
            key: ValueKey("more-replies-${comment.id}"),
            depth: childDepth,
            label: l10n.showMoreReplies,
            onPressed: () => controller.loadMoreReplies(comment.id),
          ),
        );
      }
    }

    if (focused != null) {
      addBranch(focused, 0);
    } else {
      for (final comment in state.topComments) {
        addBranch(comment, 0);
      }
    }

    final top = state.top;
    Widget? footer;
    if (focused == null) {
      if (top.loading) {
        footer = const Padding(
          padding: EdgeInsets.all(Sizes.medium),
          child: Center(child: CircularProgressIndicator()),
        );
      } else if (top.failed) {
        footer = Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.commentsLoadFailed),
              TextButton(
                onPressed: top.loaded ? controller.loadMore : controller.refresh,
                child: Text(l10n.retry),
              ),
            ],
          ),
        );
      } else if (top.hasMore) {
        footer = Center(
          child: TextButton(
            key: const ValueKey("load-more-comments"),
            onPressed: controller.loadMore,
            child: Text(l10n.loadMoreComments),
          ),
        );
      } else if (top.loaded && rows.isEmpty) {
        footer = Padding(
          padding: const EdgeInsets.all(Sizes.large),
          child: Text(
            l10n.commentsEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        );
      }
    }
    if (footer != null) rows.add(footer);

    final count = candle.commentsCount + countDelta.value;

    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = MediaQuery.viewInsetsOf(context).bottom;
        final available = constraints.maxHeight;
        var sheetHeight = available * height.value;
        if (insets > 0) {
          sheetHeight = sheetHeight.clamp(
            (insets + CommentLayout.minListHeight).clamp(0, available),
            available,
          );
        }

        void drag(DragUpdateDetails details) {
          height.value = (height.value - details.primaryDelta! / available).clamp(0, 1);
        }

        void release(DragEndDetails details) {
          final velocity = details.primaryVelocity ?? 0;
          if (height.value < CommentLayout.closeBelow || velocity > CommentLayout.flingVelocity) {
            Navigator.of(context).pop();
            return;
          }
          final target =
              velocity < -500 ||
                  height.value > (CommentLayout.sheetHeight + CommentLayout.fullHeight) / 2
              ? CommentLayout.fullHeight
              : CommentLayout.sheetHeight;
          height.animateTo(
            target,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }

        return SizedBox(
          height: sheetHeight,
          child: ScaffoldMessenger(
            key: messenger,
            child: Scaffold(
              backgroundColor: AppColors.transparent,
              resizeToAvoidBottomInset: false,
              body: Padding(
                padding: EdgeInsets.only(bottom: insets),
                child: Column(
                  children: [
                    GestureDetector(
                      key: const ValueKey("comments-sheet-header"),
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: drag,
                      onVerticalDragEnd: release,
                      child: _Header(
                        title: focused == null ? "${l10n.comments} · $count" : l10n.comments,
                        onBack: focused == null
                            ? null
                            : () => focus.value = [...focus.value]..removeLast(),
                        onClose: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const Divider(height: Sizes.hairline),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          focus.value = const [];
                          await controller.refresh();
                        },
                        child: ListView.builder(
                          key: const ValueKey("comments-list"),
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            Sizes.medium,
                            Sizes.small,
                            Sizes.small,
                            Sizes.medium,
                          ),
                          itemCount: rows.length,
                          itemBuilder: (_, index) => rows[index],
                        ),
                      ),
                    ),
                    const Divider(height: Sizes.hairline),
                    SafeArea(
                      top: false,
                      child: CommentComposer(
                        signedIn: userId != null,
                        replyTo: replyTo.value,
                        onCancelReply: () => replyTo.value = null,
                        onSend: send,
                        onSignIn: () {
                          Navigator.of(context).pop();
                          onSignIn();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onClose, this.onBack});

  final String title;
  final VoidCallback onClose;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: Sizes.small),
        child: Container(
          width: Sizes.large,
          height: Sizes.extraSmall,
          decoration: BoxDecoration(
            color: AppColors.outlineMuted,
            borderRadius: BorderRadius.circular(AppRadii.small),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sizes.small),
        child: Row(
          children: [
            if (onBack != null)
              IconButton(
                key: const ValueKey("comments-back"),
                tooltip: context.l10n.backToComments,
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              )
            else
              const SizedBox(width: kMinInteractiveDimension),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppFontSizes.subtitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: context.l10n.close,
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    ],
  );
}
