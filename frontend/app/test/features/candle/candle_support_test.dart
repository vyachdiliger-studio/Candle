import "package:candle_frontend/features/candle/data/models/candle_dto.dart";
import "package:candle_frontend/features/candle/domain/models/candle.dart";
import "package:candle_frontend/features/candle/presentation/widgets/candle_actions.dart";
import "package:candle_frontend/features/candle/presentation/widgets/candle_support_count.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  Candle candle(int count) => Candle(
    id: 1,
    createdAt: DateTime.utc(2026),
    ignitedAt: DateTime.utc(2026),
    extinguishedAt: DateTime.utc(2027),
    location: null,
    supportersCount: count,
  );

  test("support count survives DTO conversion and defaults for older responses", () {
    final dto = CandleDto.fromDomain(candle(12));
    expect(CandleDto.fromJson(dto.toJson()).toDomain().supportersCount, 12);
    final legacy = dto.toJson()..remove("supportersCount");
    expect(CandleDto.fromJson(legacy).toDomain().supportersCount, 0);
  });

  const supportExplanations = {
    "ru": ("Russian", "Поддержали 12 человек"),
    "th": ("Thai", "มีผู้ร่วมส่งกำลังใจ 12 คน"),
  };
  for (final MapEntry(key: locale, value: (language, explanation)) in supportExplanations.entries) {
    testWidgets("$language candle actions fit a narrow screen and explain the support count", (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CandleSupportCount(count: 12),
                  CandleActions(candle: candle(12), owned: true, canReport: false),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("12"), findsOneWidget);
      final actions = tester.widget<Wrap>(
        find.descendant(
          of: find.byType(CandleActions),
          matching: find.byType(Wrap),
        ),
      );
      expect(actions.alignment, WrapAlignment.center);
      expect(
        tester.getCenter(find.byIcon(Icons.local_fire_department)).dy,
        lessThan(tester.getCenter(find.text("12")).dy),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(CandleSupportCount));
      await tester.pumpAndSettle();
      expect(find.text(explanation), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
