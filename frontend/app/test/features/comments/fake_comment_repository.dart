import "package:candle_frontend/features/candle/domain/models/candle.dart";
import "package:candle_frontend/features/comments/domain/candle_comment.dart";
import "package:candle_frontend/features/comments/domain/comment_repository.dart";
import "package:dio/dio.dart";

/// In-memory comment thread with the server's ordering and page size.
class FakeCommentRepository implements CommentRepository {
  FakeCommentRepository({this.pageSize = 2});

  final int pageSize;
  final List<CandleComment> all = [];
  int requests = 0;
  bool failCreate = false;

  /// The API's error code for a failed create; null for a network failure.
  String? createError;
  bool failDelete = false;
  final deleted = <int>[];

  /// Authors who deleted their account: their comments become placeholders.
  final goneAuthors = <int>{};
  var _nextId = 1;
  var _clock = DateTime.utc(2026, 1, 1);

  CandleComment add(String text, {int? parent, int authorId = 7, String username = "lena"}) {
    final parentComment = parent == null ? null : all.firstWhere((c) => c.id == parent);
    _clock = _clock.add(const Duration(minutes: 1));
    final comment = CandleComment(
      id: _nextId++,
      candleId: 1,
      createdAt: _clock,
      parentCommentId: parent,
      rootCommentId: parentComment == null ? null : parentComment.rootCommentId ?? parent,
      depth: parentComment == null ? 0 : parentComment.depth + 1,
      author: CandleAuthor(id: authorId, username: username),
      text: text,
    );
    all.add(comment);
    return comment;
  }

  bool _deleted(CandleComment c) => deleted.contains(c.id);
  bool _live(CandleComment c) => !_deleted(c) && !goneAuthors.contains(c.author?.id);

  int _liveBelow(CandleComment c) {
    final children = all.where((d) => d.parentCommentId == c.id);
    return children.fold(0, (sum, d) => sum + (_live(d) ? 1 : 0) + _liveBelow(d));
  }

  CandleComment _view(CandleComment c) =>
      c.copyWith(repliesCount: _liveBelow(c), isDeleted: !_live(c));

  CommentPage _page(List<CandleComment> items, String? cursor) {
    final visible = items.where((c) => !_deleted(c) && (_live(c) || _liveBelow(c) > 0)).toList();
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + pageSize).clamp(0, visible.length);
    return CommentPage(
      visible.sublist(start, end).map(_view).toList(),
      end < visible.length ? "$end" : null,
    );
  }

  @override
  Future<CommentPage> comments(int candleId, {String? cursor}) async {
    requests++;
    final top = all.where((c) => c.parentCommentId == null).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _page(top, cursor);
  }

  @override
  Future<CommentPage> replies(int candleId, int commentId, {String? cursor}) async {
    requests++;
    final replies = all.where((c) => c.parentCommentId == commentId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return _page(replies, cursor);
  }

  @override
  Future<CandleComment> create(int candleId, {required String text, int? parentCommentId}) async {
    if (failCreate) {
      final request = RequestOptions(path: "/candles/$candleId/comments");
      throw createError == null
          ? DioException(requestOptions: request, type: DioExceptionType.connectionError)
          : DioException(
              requestOptions: request,
              response: Response(requestOptions: request, statusCode: 400, data: createError),
            );
    }
    return add(text, parent: parentCommentId, authorId: 42, username: "me");
  }

  @override
  Future<void> delete(int candleId, int commentId) async {
    if (failDelete) throw Exception("offline");
    void branch(int id) {
      deleted.add(id);
      for (final child in all.where((c) => c.parentCommentId == id)) {
        branch(child.id);
      }
    }

    branch(commentId);
  }
}
