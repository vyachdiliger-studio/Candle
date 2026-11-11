import "package:riverpod_annotation/riverpod_annotation.dart";

import "../../../core/security/session_epoch.dart";
import "../../candle/application/candle_controller.dart";
import "../../candle/application/candle_gallery_controller.dart";
import "../../map/application/map_controller.dart";
import "../data/dio_moderation_repository.dart";
import "../domain/blocked_user.dart";
import "../domain/report_reason.dart";

part "moderation_controller.g.dart";

@riverpod
Future<List<BlockedUser>> blockedUsers(Ref ref) {
  ref.watch(sessionEpochProvider);
  return ref.watch(moderationRepositoryProvider).blockedUsers();
}

@riverpod
class ModerationController extends _$ModerationController {
  @override
  FutureOr<void> build() {
    ref.watch(sessionEpochProvider);
  }

  Future<bool> report({required ReportReason reason, int? candleId, int? userId}) => _run(
    () => ref
        .read(moderationRepositoryProvider)
        .report(
          reason: reason,
          candleId: candleId,
          userId: userId,
        ),
  );

  Future<bool> setBlocked(int userId, {required bool blocked}) => _run(() async {
    final operationRef = ref;
    await ref.read(moderationRepositoryProvider).setBlocked(userId, blocked: blocked);
    if (!operationRef.mounted) throw const SessionChanged();
    if (blocked) ref.read(candleGalleryProvider.notifier).hideAuthor(userId);
    ref.invalidate(blockedUsersProvider);
    ref.invalidate(candleGalleryProvider);
    ref.invalidate(candleControllerProvider);
    ref.invalidate(mapControllerProvider);
  });

  Future<bool> _run(Future<void> Function() action) async {
    if (state.isLoading) return false;
    final operationRef = ref;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (!operationRef.mounted) return false;
    state = result;
    return !result.hasError;
  }
}
