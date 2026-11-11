import "package:candle_frontend/l10n/generated/app_localizations.dart";
import "package:candle_frontend/features/candle/presentation/widgets/candle_burn_hint.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("hint plays on activation, lets taps through and does not replay on rebuild", (
    tester,
  ) async {
    var taps = 0;
    Widget scene(bool active) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      home: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const SizedBox.expand(),
            ),
            CandleBurnHint(active: active),
          ],
        ),
      ),
    );
    double opacity() => tester
        .widget<Opacity>(
          find.descendant(of: find.byType(CandleBurnHint), matching: find.byType(Opacity)),
        )
        .opacity;

    await tester.pumpWidget(scene(true));
    await tester.pump(const Duration(milliseconds: 500));
    expect(opacity(), 1);
    await tester.tapAt(tester.getCenter(find.byType(CandleBurnHint)));
    expect(taps, 1);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(opacity(), 0);

    await tester.pumpWidget(scene(true));
    await tester.pump(const Duration(milliseconds: 500));
    expect(opacity(), 0);

    await tester.pumpWidget(scene(false));
    expect(find.text("Tap to keep burning"), findsNothing);
    await tester.pumpWidget(scene(true));
    await tester.pump(const Duration(milliseconds: 500));
    expect(opacity(), 1);
    await tester.pumpAndSettle();
  });
}
