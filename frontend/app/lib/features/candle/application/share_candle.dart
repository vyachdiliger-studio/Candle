import "package:candle_frontend/common/utils/string_extension.dart";
import "package:candle_frontend/core/config/app_config.dart";
import "package:candle_frontend/core/platform/telegram_mini_app.dart";
import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:share_plus/share_plus.dart";

import "../domain/models/candle.dart";

enum ShareRoute { system, telegram, dialog }

/// Where a share goes. Browsers that expose the Web Share API on desktop
/// often open nothing yet report success, so on desktop the app's own dialog
/// is the only route that is guaranteed to show. Telegram's Android and desktop
/// WebViews have no share sheet either, but the client can open its own chat
/// picker; iOS already has a working system sheet.
ShareRoute chooseShareRoute({
  required bool web,
  required TargetPlatform platform,
  required bool miniApp,
}) {
  if (!web) return ShareRoute.system;
  if (miniApp && platform != TargetPlatform.iOS) return ShareRoute.telegram;
  return switch (platform) {
    TargetPlatform.android || TargetPlatform.iOS => ShareRoute.system,
    _ => ShareRoute.dialog,
  };
}

Uri candleShareLink(Candle candle) =>
    Uri.parse(AppConfig.shareBaseUrl).replace(path: "/candles/${candle.id}");

/// The invitation without the link, for places that carry the link separately.
String candleShareCaption(Candle candle, {required String invitation}) {
  final message = candle.message?.trim().nullIfEmpty();
  return [
    invitation,
    if (message != null) "\"$message\"",
  ].join("\n\n");
}

String candleShareText(Candle candle, {required String invitation}) =>
    "${candleShareCaption(candle, invitation: invitation)}\n\n${candleShareLink(candle)}";

/// Returns whether the share was handled; false means the caller should show
/// the in-app dialog.
Future<bool> tryShareCandle(
  Candle candle, {
  required String invitation,
  required String subject,
  Rect? sharePositionOrigin,
}) async {
  final route = chooseShareRoute(
    web: kIsWeb,
    platform: defaultTargetPlatform,
    miniApp: isTelegramMiniApp,
  );
  switch (route) {
    case ShareRoute.dialog:
      return false;
    case ShareRoute.telegram:
      return openTelegramLink(
        Uri.https("t.me", "/share/url", {
          "url": candleShareLink(candle).toString(),
          "text": candleShareCaption(candle, invitation: invitation),
        }).toString(),
      );
    case ShareRoute.system:
      break;
  }
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: candleShareText(candle, invitation: invitation),
        subject: subject,
        // iPad anchors the share sheet to whatever was tapped; without this it
        // throws rather than guessing.
        sharePositionOrigin: sharePositionOrigin,
        mailToFallbackEnabled: false,
      ),
    );
    // Web returns unavailable even after successful sharing; cancellation also completes normally.
    return true;
  } catch (_) {
    if (!kIsWeb) rethrow;
    return false;
  }
}
