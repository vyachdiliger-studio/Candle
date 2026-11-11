import "dart:async";

import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/features/candle/domain/models/candle.dart";
import "package:candle_frontend/features/candle/presentation/candle_rive_loader_provider.dart";
import "package:candle_frontend/features/candle/presentation/widgets/candle_rive_icon.dart";
import "package:candle_frontend/features/map/presentation/widgets/candle_map_mark.dart";
import "package:candle_frontend/features/map/presentation/widgets/candle_marker_badge.dart";
import "package:candle_frontend/features/map/presentation/widgets/selected_candle_burn_ring.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  Future<void> pumpMarker(
    WidgetTester tester, {
    bool own = true,
    int count = 1,
    bool selected = false,
    double textScale = 1,
    VoidCallback? onTap,
  }) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Keep native animation loading out of layout and interaction tests.
        candleRiveFileProvider.overrideWith((ref) => Completer<Never>().future),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: CandleMapMarker.diameter,
                child: CandleMapMarker(
                  candle: selected
                      ? Candle(
                          id: 1,
                          createdAt: DateTime.utc(2020),
                          ignitedAt: DateTime.utc(2020),
                          extinguishedAt: DateTime.utc(2021),
                          location: null,
                        )
                      : null,
                  count: count,
                  hasOwnCandle: own,
                  isSelected: selected,
                  onTap: onTap,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets("an own candle has a badge; a foreign single candle does not", (tester) async {
    await pumpMarker(tester);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text("1"), findsNothing);

    await pumpMarker(tester, own: false);
    expect(find.byType(CandleMarkerBadge), findsNothing);
  });

  testWidgets("a cluster keeps its count and only shows the owner icon when needed", (
    tester,
  ) async {
    await pumpMarker(tester, count: 12);
    expect(find.text("12"), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);

    await pumpMarker(tester, count: 12, own: false);
    expect(find.text("12"), findsOneWidget);
    expect(find.byIcon(Icons.person), findsNothing);
  });

  for (final selected in [false, true]) {
    testWidgets("the entire badge and candle share one tap action (selected=$selected)", (
      tester,
    ) async {
      var taps = 0;
      await pumpMarker(tester, selected: selected, onTap: () => taps++);
      final badge = tester.getRect(find.byType(CandleMarkerBadge));
      // Regression: the lower half used to paint outside its hit-test box.
      await tester.tapAt(Offset(badge.center.dx, badge.bottom - 2));
      await tester.pump();
      expect(taps, 1);

      await tester.tapAt(tester.getCenter(find.byType(CandleIconRive)));
      await tester.pump();
      expect(taps, 2);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byType(SelectedCandleBurnRing), selected ? findsOneWidget : findsNothing);
      if (selected) {
        expect(
          tester.getSize(find.byType(SelectedCandleBurnRing)),
          const Size.square(AppDimensions.burnRingDiameter + AppStrokes.burnRing * 2),
        );
      }
    });
  }

  testWidgets("selecting and deselecting an own cluster preserves its badge and count", (
    tester,
  ) async {
    for (final selected in [false, true, false]) {
      await pumpMarker(tester, count: 12, selected: selected);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.text("12"), findsOneWidget);
      expect(find.byType(SelectedCandleBurnRing), selected ? findsOneWidget : findsNothing);
    }
  });

  testWidgets("dragging from the badge pans instead of opening the candle", (tester) async {
    var taps = 0;
    var pans = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [candleRiveFileProvider.overrideWith((ref) => Completer<Never>().future)],
        child: MaterialApp(
          home: GestureDetector(
            onPanUpdate: (_) => pans++,
            child: Center(
              child: SizedBox.square(
                dimension: CandleMapMarker.diameter,
                child: CandleMapMarker(hasOwnCandle: true, isSelected: false, onTap: () => taps++),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.dragFrom(tester.getCenter(find.byType(CandleMarkerBadge)), const Offset(100, 0));
    await tester.pump();
    expect(taps, 0);
    expect(pans, greaterThan(0));
  });

  testWidgets("the badge does not move the candle and stays inside the marker with large text", (
    tester,
  ) async {
    await pumpMarker(tester, own: false);
    final candle = tester.getRect(find.byType(CandleIconRive));
    await pumpMarker(tester);
    expect(tester.getRect(find.byType(CandleIconRive)), candle);
    final badge = tester.getRect(find.byType(CandleMarkerBadge));
    expect(badge.center.dy, closeTo(candle.bottom, 0.01));
    expect(badge.width, badge.height);
    expect(badge.width, Sizes.spacious);

    await pumpMarker(tester, count: 999999, textScale: 3);
    final marker = tester.getRect(find.byType(CandleMapMarker));
    final largeBadge = tester.getRect(find.byType(CandleMarkerBadge));
    expect(largeBadge.left, greaterThanOrEqualTo(marker.left));
    expect(largeBadge.right, lessThanOrEqualTo(marker.right));
    expect(largeBadge.bottom, lessThanOrEqualTo(marker.bottom));
    expect(tester.takeException(), isNull);
  });
}
