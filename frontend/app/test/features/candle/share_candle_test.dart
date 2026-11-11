import "package:candle_frontend/features/candle/application/share_candle.dart";
import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";

import "candle_gallery_test.dart" show candle;

ShareRoute route(TargetPlatform platform, {bool web = true, bool miniApp = false}) =>
    chooseShareRoute(web: web, platform: platform, miniApp: miniApp);

void main() {
  group("share route", () {
    test(
      "desktop browsers use the in-app dialog, since their share API can silently do nothing",
      () {
        for (final platform in [
          TargetPlatform.linux,
          TargetPlatform.windows,
          TargetPlatform.macOS,
        ]) {
          expect(route(platform), ShareRoute.dialog);
        }
      },
    );

    test("mobile browsers and native apps use the system share sheet", () {
      expect(route(TargetPlatform.android), ShareRoute.system);
      expect(route(TargetPlatform.iOS), ShareRoute.system);
      expect(route(TargetPlatform.android, web: false), ShareRoute.system);
      expect(route(TargetPlatform.linux, web: false), ShareRoute.system);
    });

    test("a Mini App shares through Telegram, except on iOS where the system sheet works", () {
      expect(route(TargetPlatform.android, miniApp: true), ShareRoute.telegram);
      expect(route(TargetPlatform.linux, miniApp: true), ShareRoute.telegram);
      expect(route(TargetPlatform.windows, miniApp: true), ShareRoute.telegram);
      expect(route(TargetPlatform.iOS, miniApp: true), ShareRoute.system);
    });
  });

  group("share text", () {
    test("the link has no stray question mark", () {
      expect(candleShareLink(candle(137610)).toString(), endsWith("/candles/137610"));
    });

    test("the caption carries the message but not the link", () {
      final shared = candle(7).copyWith(message: "  For family  ");
      expect(candleShareCaption(shared, invitation: "A candle"), contains("\"For family\""));
      expect(candleShareCaption(shared, invitation: "A candle"), isNot(contains("/candles/")));
      expect(candleShareText(shared, invitation: "A candle"), endsWith("/candles/7"));
    });
  });
}
