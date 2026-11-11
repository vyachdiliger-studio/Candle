import "package:dio/dio.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../core/network/dio_provider.dart";
import "../domain/blocked_user.dart";
import "../domain/moderation_repository.dart";
import "../domain/report_reason.dart";

final moderationRepositoryProvider = Provider<ModerationRepository>(
  (ref) => DioModerationRepository(ref.watch(dioProvider)),
);

class DioModerationRepository implements ModerationRepository {
  const DioModerationRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> report({
    required ReportReason reason,
    int? candleId,
    int? userId,
    int? commentId,
  }) async {
    final reasonCode = switch (reason) {
      ReportReason.spam => 1,
      ReportReason.harassment => 2,
      ReportReason.hate => 3,
      ReportReason.sexualContent => 4,
      ReportReason.violence => 5,
      ReportReason.other => 6,
    };
    await _dio.post(
      "/reports",
      data: {
        "reason": reasonCode,
        "candleId": ?candleId,
        "userId": ?userId,
        "commentId": ?commentId,
      },
    );
  }

  @override
  Future<List<BlockedUser>> blockedUsers() async {
    final response = await _dio.get<List<dynamic>>("/users/me/blocks");
    return response.data!
        .map(
          (item) => BlockedUser(
            id: (item["id"] as num).toInt(),
            username: item["username"] as String,
          ),
        )
        .toList();
  }

  @override
  Future<void> setBlocked(int userId, {required bool blocked}) async {
    final path = "/users/me/blocks/$userId";
    if (blocked) {
      await _dio.put(path);
    } else {
      await _dio.delete(path);
    }
  }
}
