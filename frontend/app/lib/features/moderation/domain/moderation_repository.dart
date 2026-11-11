import "blocked_user.dart";
import "report_reason.dart";

abstract interface class ModerationRepository {
  Future<void> report({
    required ReportReason reason,
    int? candleId,
    int? userId,
    int? commentId,
  });
  Future<List<BlockedUser>> blockedUsers();
  Future<void> setBlocked(int userId, {required bool blocked});
}
