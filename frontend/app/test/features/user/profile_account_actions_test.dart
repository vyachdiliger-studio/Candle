import "package:candle_frontend/features/user/presentation/widgets/profile_account_actions.dart";
import "package:candle_frontend/features/user/presentation/widgets/profile_action_button.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  for (final language in ["en", "ru"]) {
    testWidgets("Account actions adapt to width and text scale ($language)", (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Future<void> show(double width, double scale) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  child: MediaQuery(
                    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                    child: ProfileAccountActions(onLogout: () {}, onDelete: () {}),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final text in tester.widgetList<Text>(
          find.descendant(
            of: find.byType(ProfileAccountActions),
            matching: find.byType(Text),
          ),
        )) {
          expect(text.style?.overflow, isNot(TextOverflow.ellipsis));
        }
      }

      final buttons = find.byType(ProfileActionButton);
      await show(1300, 1);
      expect(tester.getTopLeft(buttons.at(0)).dy, tester.getTopLeft(buttons.at(1)).dy);
      await show(280, 1);
      expect(
        tester.getTopLeft(buttons.at(1)).dy,
        greaterThan(tester.getBottomLeft(buttons.at(0)).dy),
      );
      await show(280, 2);
      expect(
        tester.getTopLeft(buttons.at(1)).dy,
        greaterThan(tester.getBottomLeft(buttons.at(0)).dy),
      );
    });
  }
}
