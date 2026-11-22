import "package:candle_frontend/features/comments/presentation/widgets/comment_composer.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("the field has equal space above and below", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: CommentComposer(signedIn: true, onSend: (_) async => true, onSignIn: () {}),
          ),
        ),
      ),
    );
    final composer = tester.getRect(find.byType(CommentComposer));
    final field = tester.getRect(find.byKey(const ValueKey("comment-field")));
    expect(field.top - composer.top, composer.bottom - field.bottom);
  });

  testWidgets("the limit counts emoji as one character, as the API does", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CommentComposer(signedIn: true, onSend: (_) async => true, onSignIn: () {}),
        ),
      ),
    );
    const candle = "\u{1F56F}\u{FE0F}";
    await tester.enterText(find.byKey(const ValueKey("comment-field")), candle * 1001);
    await tester.pump();
    final field = tester.widget<TextField>(find.byKey(const ValueKey("comment-field")));
    expect(field.controller!.text, candle * CommentComposer.maxLength);
    expect(find.text("1000/1000"), findsOneWidget);
  });
}
