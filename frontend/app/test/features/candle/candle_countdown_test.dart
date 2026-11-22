import "package:candle_frontend/common/ui/widgets/center_between.dart";
import "package:candle_frontend/features/candle/presentation/widgets/candle_countdown.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  Future<void> show(
    WidgetTester tester, {
    Duration remaining = const Duration(days: 27, hours: 21, minutes: 24, seconds: 13),
    String locale = "en",
    double width = 320,
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CenterBetween(
                    left: const SizedBox(key: ValueKey("menu"), width: 52, height: 52),
                    right: const SizedBox(key: ValueKey("map"), width: 46, height: 46),
                    child: CandleCountdownDisplay(remaining: remaining),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets("values sit above their localized labels, including zero days", (tester) async {
    const localizedLabels = {
      "en": ["days", "hours", "min", "sec"],
      "ru": ["дней", "часов", "минут", "секунд"],
      "uk": ["днів", "годин", "хвилин", "секунд"],
      "th": ["วัน", "ชั่วโมง", "นาที", "วินาที"],
    };
    for (final locale in localizedLabels.keys) {
      await show(
        tester,
        locale: locale,
        remaining: const Duration(hours: 21, minutes: 24, seconds: 13),
      );
      final labels = localizedLabels[locale]!;
      final values = ["0", "21", "24", "13"];
      for (var i = 0; i < labels.length; i++) {
        final value = tester.getRect(find.text(values[i]));
        final label = tester.getRect(find.text(labels[i]));
        expect(value.bottom, lessThanOrEqualTo(label.top));
        expect(value.center.dx, closeTo(label.center.dx, 0.01));
      }
    }
  });

  testWidgets("narrow headers, long days and enlarged text stay between controls", (tester) async {
    for (final width in [280.0, 320.0, 600.0]) {
      for (final locale in ["en", "ru", "uk", "th"]) {
        await show(
          tester,
          width: width,
          locale: locale,
          scale: 2,
          remaining: const Duration(days: 12345, hours: 21, minutes: 24, seconds: 13),
        );
        expect(tester.takeException(), isNull);
        final group = tester.getRect(find.byType(FittedBox));
        expect(
          group.left,
          greaterThanOrEqualTo(tester.getRect(find.byKey(const ValueKey("menu")).first).right),
        );
        expect(
          group.right,
          lessThanOrEqualTo(tester.getRect(find.byKey(const ValueKey("map")).last).left),
        );
        expect(find.text("12345"), findsOneWidget);
      }
    }
  });

  testWidgets("ticking digits keep label positions stable", (tester) async {
    await show(tester, remaining: const Duration(days: 27, hours: 11, minutes: 11, seconds: 11));
    final before = [
      for (final label in ["days", "hours", "min", "sec"]) tester.getRect(find.text(label)),
    ];
    await show(tester);
    final after = [
      for (final label in ["days", "hours", "min", "sec"]) tester.getRect(find.text(label)),
    ];
    expect(after, before);
  });
}
