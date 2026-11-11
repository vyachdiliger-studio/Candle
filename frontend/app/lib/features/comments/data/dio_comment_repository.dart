import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../core/network/dio_provider.dart";
import "../../candle/domain/models/candle.dart";
import "../domain/candle_comment.dart";
import "../domain/comment_repository.dart";

final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => DioCommentRepository(ref.watch(dioProvider)),
);

class DioCommentRepository implements CommentRepository {
  const DioCommentRepository(this._dio);

  final Dio _dio;

  static const pageSize = 20;

  @override
  Future<CommentPage> comments(int candleId, {String? cursor}) =>
      _page("/candles/$candleId/comments", cursor);

  @override
  Future<CommentPage> replies(int candleId, int commentId, {String? cursor}) =>
      _page("/candles/$candleId/comments/$commentId/replies", cursor);

  @override
  Future<CandleComment> create(int candleId, {required String text, int? parentCommentId}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      "/candles/$candleId/comments",
      data: {"text": text, "parentCommentId": ?parentCommentId},
    );
    return commentFromJson(response.data!);
  }

  @override
  Future<void> delete(int candleId, int commentId) =>
      _dio.delete<void>("/candles/$candleId/comments/$commentId");

  Future<CommentPage> _page(String path, String? cursor) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: {"limit": pageSize, "cursor": ?cursor},
    );
    final data = response.data!;
    return CommentPage(
      (data["items"] as List).map((it) => commentFromJson(it as Map<String, dynamic>)).toList(),
      data["nextCursor"] as String?,
    );
  }
}

CandleComment commentFromJson(Map<String, dynamic> json) {
  final author = json["author"] as Map<String, dynamic>?;
  return CandleComment(
    id: (json["id"] as num).toInt(),
    candleId: (json["candleId"] as num).toInt(),
    parentCommentId: (json["parentCommentId"] as num?)?.toInt(),
    rootCommentId: (json["rootCommentId"] as num?)?.toInt(),
    depth: (json["depth"] as num?)?.toInt() ?? 0,
    author: author == null ? null : CandleAuthor.fromJson(author),
    text: json["text"] as String?,
    isDeleted: json["isDeleted"] as bool? ?? false,
    createdAt: DateTime.parse(json["createdAt"] as String),
    repliesCount: (json["repliesCount"] as num?)?.toInt() ?? 0,
  );
}
