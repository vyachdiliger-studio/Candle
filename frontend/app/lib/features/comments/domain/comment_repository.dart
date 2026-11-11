import "candle_comment.dart";

abstract interface class CommentRepository {
  /// Top-level comments, newest first.
  Future<CommentPage> comments(int candleId, {String? cursor});

  /// Direct replies to [commentId], oldest first.
  Future<CommentPage> replies(int candleId, int commentId, {String? cursor});

  Future<CandleComment> create(int candleId, {required String text, int? parentCommentId});

  Future<void> delete(int candleId, int commentId);
}
