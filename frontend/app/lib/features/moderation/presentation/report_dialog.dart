import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../application/moderation_controller.dart";
import "../domain/report_reason.dart";

class ReportDialog extends ConsumerWidget {
  const ReportDialog({super.key, this.candleId, this.userId});

  final int? candleId;
  final int? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(moderationControllerProvider);
    return PopScope(
      canPop: !action.isLoading,
      child: AlertDialog(
        title: Text(candleId != null ? context.l10n.reportCandle : context.l10n.reportAuthor),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.l10n.reportReason),
              const SizedBox(height: Sizes.regular),
              for (final reason in ReportReason.values)
                TextButton(
                  onPressed: action.isLoading
                      ? null
                      : () async {
                          final sent = await ref
                              .read(moderationControllerProvider.notifier)
                              .report(
                                reason: reason,
                                candleId: candleId,
                                userId: userId,
                              );
                          if (sent && context.mounted) Navigator.of(context).pop(true);
                        },
                  child: Text(switch (reason) {
                    ReportReason.spam => context.l10n.reportSpam,
                    ReportReason.harassment => context.l10n.reportHarassment,
                    ReportReason.hate => context.l10n.reportHate,
                    ReportReason.sexualContent => context.l10n.reportSexual,
                    ReportReason.violence => context.l10n.reportViolence,
                    ReportReason.other => context.l10n.reportOther,
                  }),
                ),
              if (action.isLoading) const LinearProgressIndicator(),
              if (action.hasError) Text(context.l10n.reportFailed),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: action.isLoading ? null : () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
        ],
      ),
    );
  }
}
