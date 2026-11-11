import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:candle_frontend/l10n/localization.dart";

import "../../../moderation/presentation/candle_safety_menu.dart";
import "../../domain/models/candle.dart";
import "../share_candle.dart";
import "background/background_button.dart";

class CandleActions extends StatelessWidget {
  const CandleActions({
    super.key,
    required this.candle,
    required this.owned,
    required this.canReport,
  });

  final Candle candle;
  final bool owned;
  final bool canReport;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (owned) BackgroundButton(candleId: candle.id),
      if (!owned && canReport && candle.author != null)
        CandleSafetyMenu(candleId: candle.id, authorId: candle.author!.id),
      if (candle.location != null || owned)
        TextButton.icon(
          onPressed: () => context.pushNamed(
            "map",
            queryParameters: {"focus": "${candle.id}"},
            extra: candle,
          ),
          icon: const Icon(Icons.place_outlined),
          label: Text(candle.location == null ? context.l10n.placeOnMap : context.l10n.onMap),
        ),
      TextButton.icon(
        onPressed: () async {
          try {
            await shareCandle(candle, context: context);
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.shareFailed)),
              );
            }
          }
        },
        icon: const Icon(Icons.share_outlined),
        label: Text(context.l10n.share),
      ),
    ],
  );
}
