import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";

import "../application/share_candle.dart";
import "../domain/models/candle.dart";
import "widgets/share_link_dialog.dart";

Future<void> shareCandle(Candle candle, {required BuildContext context}) async {
  final invitation = context.l10n.shareInvitation;
  final box = context.findRenderObject();
  final origin = box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null;
  final handled = await tryShareCandle(
    candle,
    invitation: invitation,
    subject: context.l10n.shareSubject,
    sharePositionOrigin: origin,
  );
  if (handled || !context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (_) => ShareLinkDialog(text: candleShareText(candle, invitation: invitation)),
  );
}
