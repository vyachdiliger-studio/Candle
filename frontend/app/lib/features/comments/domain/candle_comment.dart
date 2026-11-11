import "../../candle/domain/models/candle.dart";

/// A comment in a candle's thread. A deleted comment that still has live replies
/// arrives as a placeholder: [isDeleted] is true and [author] and [text] are null.
class CandleComment {
  const CandleComment({
    required this.id,
    required this.candleId,
    required this.createdAt,
    this.parentCommentId,
    this.rootCommentId,
    this.depth = 0,
    this.author,
    this.text,
    this.isDeleted = false,
    this.repliesCount = 0,
  });

  final int id;
  final int candleId;
  final int? parentCommentId;
  final int? rootCommentId;
  final int depth;
  final CandleAuthor? author;
  final String? text;
  final bool isDeleted;
  final DateTime createdAt;

  /// Live comments anywhere below this one.
  final int repliesCount;

  CandleComment copyWith({int? repliesCount, bool? isDeleted}) {
    final deleted = isDeleted ?? this.isDeleted;
    return CandleComment(
      id: id,
      candleId: candleId,
      createdAt: createdAt,
      parentCommentId: parentCommentId,
      rootCommentId: rootCommentId,
      depth: depth,
      author: deleted ? null : author,
      text: deleted ? null : text,
      isDeleted: deleted,
      repliesCount: repliesCount ?? this.repliesCount,
    );
  }
}

class CommentPage {
  const CommentPage(this.items, this.nextCursor);

  final List<CandleComment> items;
  final String? nextCursor;
}
