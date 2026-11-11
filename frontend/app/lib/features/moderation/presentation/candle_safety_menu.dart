import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "block_author_dialog.dart";
import "report_dialog.dart";

enum _SafetyAction { reportCandle, reportAuthor, blockAuthor }

class CandleSafetyMenu extends StatelessWidget {
  const CandleSafetyMenu({super.key, required this.candleId, required this.authorId});

  final int candleId;
  final int authorId;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SafetyAction>(
      tooltip: context.l10n.reportOrBlock,
      icon: const Icon(Icons.more_horiz),
      style: IconButton.styleFrom(visualDensity: Theme.of(context).visualDensity),
      itemBuilder: (_) => [
        PopupMenuItem(value: _SafetyAction.reportCandle, child: Text(context.l10n.reportCandle)),
        PopupMenuItem(value: _SafetyAction.reportAuthor, child: Text(context.l10n.reportAuthor)),
        PopupMenuItem(value: _SafetyAction.blockAuthor, child: Text(context.l10n.blockAuthor)),
      ],
      onSelected: (action) async {
        if (action == _SafetyAction.blockAuthor) {
          final blocked = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => BlockAuthorDialog(userId: authorId),
          );
          if (blocked == true && context.mounted) context.go("/");
          return;
        }
        final sent = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => ReportDialog(
            candleId: action == _SafetyAction.reportCandle ? candleId : null,
            userId: action == _SafetyAction.reportAuthor ? authorId : null,
          ),
        );
        if (sent == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.reportReceived)),
          );
        }
      },
    );
  }
}
