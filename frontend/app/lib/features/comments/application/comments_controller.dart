import "package:dio/dio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../core/security/session_epoch.dart";
import "../data/dio_comment_repository.dart";
import "../domain/candle_comment.dart";
import "../domain/comment_repository.dart";

part "comments_controller.g.dart";

enum CommentPostResult {
  sent,

  /// The server refused the text: empty or over the length limit.
  invalidText,

  /// The server refused otherwise or could not be reached.
  failed,
}

/// One paginated list: a candle's top-level comments or one comment's replies.
class CommentList {
  const CommentList({
    this.ids = const [],
    this.nextCursor,
    this.loading = false,
    this.loaded = false,
    this.failed = false,
  });

  final List<int> ids;
  final String? nextCursor;
  final bool loading;
  final bool loaded;
  final bool failed;

  bool get hasMore => nextCursor != null;

  CommentList copyWith({
    List<int>? ids,
    String? Function()? nextCursor,
    bool? loading,
    bool? loaded,
    bool? failed,
  }) => CommentList(
    ids: ids ?? this.ids,
    nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
    loading: loading ?? this.loading,
    loaded: loaded ?? this.loaded,
    failed: failed ?? this.failed,
  );
}

class CommentsState {
  const CommentsState({
    this.comments = const {},
    this.top = const CommentList(),
    this.replies = const {},
    this.expanded = const {},
  });

  final Map<int, CandleComment> comments;
  final CommentList top;

  /// Loaded reply lists by parent comment id.
  final Map<int, CommentList> replies;

  /// Comments whose replies are shown.
  final Set<int> expanded;

  List<CandleComment> get topComments => [for (final id in top.ids) ?comments[id]];

  List<CandleComment> repliesOf(int id) => [
    for (final r in replies[id]?.ids ?? const <int>[]) ?comments[r],
  ];

  CommentList repliesList(int id) => replies[id] ?? const CommentList();

  bool isExpanded(int id) => expanded.contains(id);

  CommentsState copyWith({
    Map<int, CandleComment>? comments,
    CommentList? top,
    Map<int, CommentList>? replies,
    Set<int>? expanded,
  }) => CommentsState(
    comments: comments ?? this.comments,
    top: top ?? this.top,
    replies: replies ?? this.replies,
    expanded: expanded ?? this.expanded,
  );
}

/// A candle's comment thread as a tree of paginated lists. Kept only while the
/// comments sheet is open; every opening starts from a fresh first page.
@riverpod
class CommentsController extends _$CommentsController {
  @override
  CommentsState build(int candleId) {
    ref.watch(sessionEpochProvider);
    return const CommentsState();
  }

  CommentRepository get _repository => ref.read(commentRepositoryProvider);

  /// Reloads the first page of top-level comments and collapses every branch.
  Future<void> refresh() async {
    state = state.copyWith(top: state.top.copyWith(loading: true, failed: false));
    final operationRef = ref;
    try {
      final page = await _repository.comments(candleId);
      if (!operationRef.mounted) return;
      state = CommentsState(
        comments: {for (final c in page.items) c.id: c},
        top: CommentList(
          ids: [for (final c in page.items) c.id],
          nextCursor: page.nextCursor,
          loaded: true,
        ),
      );
    } catch (_) {
      if (!operationRef.mounted) return;
      state = state.copyWith(top: state.top.copyWith(loading: false, failed: true));
    }
  }

  Future<void> loadMore() async {
    final top = state.top;
    if (top.loading || !top.hasMore) return;
    state = state.copyWith(top: top.copyWith(loading: true, failed: false));
    final operationRef = ref;
    try {
      final page = await _repository.comments(candleId, cursor: top.nextCursor);
      if (!operationRef.mounted) return;
      state = state.copyWith(
        comments: {...state.comments, for (final c in page.items) c.id: c},
        top: _append(state.top, page),
      );
    } catch (_) {
      if (!operationRef.mounted) return;
      state = state.copyWith(top: state.top.copyWith(loading: false, failed: true));
    }
  }

  /// Expands [commentId] and loads its first page of replies if needed.
  Future<void> showReplies(int commentId) async {
    state = state.copyWith(expanded: {...state.expanded, commentId});
    if (!state.repliesList(commentId).loaded) await _loadReplies(commentId);
  }

  Future<void> loadMoreReplies(int commentId) => _loadReplies(commentId);

  void hideReplies(int commentId) {
    state = state.copyWith(expanded: {...state.expanded}..remove(commentId));
  }

  /// Posts a comment, or a reply when [parentCommentId] is set, and shows it at
  /// once.
  Future<CommentPostResult> post(String text, {int? parentCommentId}) async {
    final operationRef = ref;
    final CandleComment created;
    try {
      created = await _repository.create(
        candleId,
        text: text.trim(),
        parentCommentId: parentCommentId,
      );
    } on DioException catch (error) {
      return error.response?.data == "invalid_comment_text"
          ? CommentPostResult.invalidText
          : CommentPostResult.failed;
    } catch (_) {
      return CommentPostResult.failed;
    }
    if (!operationRef.mounted) return CommentPostResult.failed;

    if (parentCommentId == null) {
      state = state.copyWith(
        comments: {...state.comments, created.id: created},
        top: state.top.copyWith(ids: [created.id, ...state.top.ids]),
      );
      return CommentPostResult.sent;
    }

    // Load what the branch already holds first, so the new reply lands after it.
    await showReplies(parentCommentId);
    if (!operationRef.mounted) return CommentPostResult.sent;
    final comments = {...state.comments, created.id: created};
    _adjustAncestors(comments, parentCommentId, 1);
    final list = state.repliesList(parentCommentId);
    state = state.copyWith(
      comments: comments,
      replies: {
        ...state.replies,
        parentCommentId: list.copyWith(
          ids: list.ids.contains(created.id) ? list.ids : [...list.ids, created.id],
          loaded: true,
        ),
      },
    );
    return CommentPostResult.sent;
  }

  /// Deletes an own comment together with its whole branch, as the server does.
  /// A placeholder (author's account deleted) left without live replies disappears.
  Future<bool> delete(int commentId) async {
    final operationRef = ref;
    try {
      await _repository.delete(candleId, commentId);
    } catch (_) {
      return false;
    }
    if (!operationRef.mounted) return false;
    final comment = state.comments[commentId];
    if (comment == null) return true;

    final comments = {...state.comments};
    var top = state.top;
    final replies = {...state.replies};
    final expanded = {...state.expanded};

    void dropBranch(int id) {
      for (final child in replies.remove(id)?.ids ?? const <int>[]) {
        dropBranch(child);
      }
      comments.remove(id);
      expanded.remove(id);
    }

    void remove(CandleComment c) {
      dropBranch(c.id);
      final parent = c.parentCommentId;
      if (parent == null) {
        top = top.copyWith(ids: [...top.ids]..remove(c.id));
      } else if (replies[parent] case final list?) {
        replies[parent] = list.copyWith(ids: [...list.ids]..remove(c.id));
      }
    }

    remove(comment);
    final removed = 1 + comment.repliesCount;
    for (final ancestor in _adjustAncestors(comments, comment.parentCommentId, -removed)) {
      if (ancestor.isDeleted && ancestor.repliesCount <= 0) remove(ancestor);
    }

    state = state.copyWith(comments: comments, top: top, replies: replies, expanded: expanded);
    return true;
  }

  /// Changes the live reply count of [parentId] and everything above it.
  /// Returns the updated ancestors, nearest first.
  List<CandleComment> _adjustAncestors(Map<int, CandleComment> comments, int? parentId, int delta) {
    final updated = <CandleComment>[];
    var id = parentId;
    while (id != null) {
      final ancestor = comments[id];
      if (ancestor == null) break;
      final next = ancestor.copyWith(repliesCount: ancestor.repliesCount + delta);
      comments[id] = next;
      updated.add(next);
      id = ancestor.parentCommentId;
    }
    return updated;
  }

  Future<void> _loadReplies(int commentId) async {
    final list = state.repliesList(commentId);
    if (list.loading || (list.loaded && !list.hasMore)) return;
    _setReplies(commentId, list.copyWith(loading: true, failed: false));
    final operationRef = ref;
    try {
      final page = await _repository.replies(candleId, commentId, cursor: list.nextCursor);
      if (!operationRef.mounted) return;
      state = state.copyWith(
        comments: {...state.comments, for (final c in page.items) c.id: c},
        replies: {...state.replies, commentId: _append(state.repliesList(commentId), page)},
      );
    } catch (_) {
      if (!operationRef.mounted) return;
      _setReplies(commentId, state.repliesList(commentId).copyWith(loading: false, failed: true));
    }
  }

  void _setReplies(int commentId, CommentList list) {
    state = state.copyWith(replies: {...state.replies, commentId: list});
  }

  /// Adds a page, skipping comments already shown (e.g. posted locally).
  static CommentList _append(CommentList list, CommentPage page) => CommentList(
    ids: [
      ...list.ids,
      for (final c in page.items)
        if (!list.ids.contains(c.id)) c.id,
    ],
    nextCursor: page.nextCursor,
    loaded: true,
  );
}
