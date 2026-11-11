import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/features/candle/domain/models/candle.dart";
import "package:candle_frontend/features/comments/data/dio_comment_repository.dart";
import "package:candle_frontend/features/comments/presentation/comment_layout.dart";
import "package:candle_frontend/features/comments/presentation/comments_sheet.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "fake_comment_repository.dart";

void main() {
  final candle = Candle(
    id: 1,
    createdAt: DateTime.utc(2026),
    ignitedAt: DateTime.utc(2026),
    extinguishedAt: DateTime.utc(2027),
    location: null,
    author: const CandleAuthor(id: 7, username: "lena"),
    commentsCount: 3,
  );

  late FakeCommentRepository repository;
  late int root;

  setUp(() {
    repository = FakeCommentRepository(pageSize: 20);
    root = repository.add("Light for grandma").id;
    repository.add("Bright memory", parent: root, authorId: 9, username: "mark");
    repository.add("Thank you", parent: root, authorId: 42, username: "me");
  });

  Future<void> open(WidgetTester tester, {int? userId, VoidCallback? onSignIn}) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [commentRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          locale: const Locale("en"),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showCommentsSheet(
                  context,
                  candle: candle,
                  userId: userId,
                  onSignIn: onSignIn ?? () {},
                ),
                child: const Text("open"),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
  }

  testWidgets("guests read the thread and are asked to sign in to write", (tester) async {
    var signIn = 0;
    await open(tester, onSignIn: () => signIn++);

    final sheet = tester.getSize(find.byType(CommentsSheet));
    expect(sheet.height / 900, closeTo(CommentLayout.sheetHeight, 0.05));
    expect(find.text("Comments · 3"), findsOneWidget);
    expect(find.text("Light for grandma"), findsOneWidget);
    expect(find.text("author"), findsOneWidget, reason: "lena lit the candle");
    expect(find.text("Reply"), findsNothing);
    expect(find.byIcon(Icons.more_horiz), findsNothing);
    expect(find.byKey(const ValueKey("comment-field")), findsNothing);

    await tester.tap(find.text("— Show 2 replies"));
    await tester.pumpAndSettle();
    expect(find.text("Bright memory"), findsOneWidget);
    expect(find.text("Thank you"), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey("comment-sign-in")));
    await tester.pumpAndSettle();
    expect(signIn, 1);
    expect(find.byType(CommentsSheet), findsNothing, reason: "the sheet closes first");
    expect(tester.takeException(), isNull);
  });

  testWidgets("signed-in users reply, delete their own comments and open deep branches", (
    tester,
  ) async {
    await open(tester, userId: 42);
    expect(find.byKey(const ValueKey("comment-field")), findsOneWidget);
    expect(
      tester.getRect(find.byIcon(Icons.more_horiz).first).right,
      greaterThan(tester.getRect(find.byType(CommentsSheet)).right - Sizes.extraLarge),
      reason: "the overflow menu sits at the end of the row",
    );

    await tester.tap(find.text("— Show 2 replies"));
    await tester.pumpAndSettle();

    // Reply to mark: the chip names him and the reply lands in his branch.
    await tester.tap(find.text("Reply").at(1));
    await tester.pumpAndSettle();
    expect(find.text("Replying to @mark"), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey("comment-field")), "  Hugs  ");
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey("comment-send")));
    await tester.pumpAndSettle();
    expect(find.text("Replying to @mark"), findsNothing);
    expect(find.text("Comments · 4"), findsOneWidget);
    expect(find.text("Hugs"), findsOneWidget);
    expect(repository.all.last.parentCommentId, repository.all[1].id);

    // A reply below the inline depth opens as a focused branch.
    final hugs = repository.all.last.id;
    repository.add("Even deeper", parent: hugs, authorId: 9, username: "mark");
    await tester.drag(find.byKey(const ValueKey("comments-list")), const Offset(0, 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text("— Show 4 replies"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("— Show 2 replies"));
    await tester.pumpAndSettle();
    expect(find.text("Even deeper"), findsNothing);
    await tester.tap(find.text("— View thread"));
    await tester.pumpAndSettle();
    expect(find.text("Even deeper"), findsOneWidget);
    expect(find.text("Light for grandma"), findsNothing);
    await tester.tap(find.byKey(const ValueKey("comments-back")));
    await tester.pumpAndSettle();
    expect(find.text("Light for grandma"), findsOneWidget);

    // Own comments can be deleted after confirmation; others can be reported.
    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await tester.pumpAndSettle();
    expect(find.text("Report comment"), findsOneWidget, reason: "lena's comment");
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    final thanks = find.byKey(ValueKey("comment-${repository.all[2].id}"));
    await tester.tap(find.descendant(of: thanks, matching: find.byIcon(Icons.more_horiz)));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Delete comment"));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey("confirm-delete-comment")));
    await tester.pumpAndSettle();
    expect(find.text("Thank you"), findsNothing);
    expect(repository.deleted, [repository.all[2].id]);
    expect(find.text("Comments · 3"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("deleting the last reply collapses its parent", (tester) async {
    repository = FakeCommentRepository(pageSize: 20);
    final parent = repository.add("Only thread");
    final mine = repository.add("Mine", parent: parent.id, authorId: 42, username: "me");
    await open(tester, userId: 42);
    await tester.tap(find.text("— Show 1 reply"));
    await tester.pumpAndSettle();
    expect(find.text("Hide replies"), findsOneWidget);

    final tile = find.byKey(ValueKey("comment-${mine.id}"));
    await tester.tap(find.descendant(of: tile, matching: find.byIcon(Icons.more_horiz)));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Delete comment"));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey("confirm-delete-comment")));
    await tester.pumpAndSettle();
    expect(find.text("Mine"), findsNothing);
    expect(find.text("Hide replies"), findsNothing);
    expect(find.textContaining("Show"), findsNothing);
  });

  testWidgets("dragging the header expands the sheet and swiping down closes it", (tester) async {
    await open(tester);
    final header = find.byKey(const ValueKey("comments-sheet-header"));
    await tester.drag(header, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(CommentsSheet)).height, greaterThan(850));

    await tester.drag(header, const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(find.byType(CommentsSheet), findsNothing);
  });
}
