import "package:candle_frontend/features/candle/presentation/widgets/candle_tap_sparks.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("sparks preserve taps, ignore drags, settle and dispose while active", (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CandleTapSparks(
            enabled: true,
            onTap: () => taps++,
            builder: (onTapUp) => GestureDetector(
              onTapUp: onTapUp,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(CandleTapSparks), const Offset(100, 0));
    expect(taps, 0);
    for (var i = 0; i < 20; i++) {
      await tester.tapAt(const Offset(100, 200));
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(taps, 20);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.tapAt(const Offset(100, 200));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
