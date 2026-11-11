import "package:candle_frontend/features/comments/application/comments_controller.dart";
import "package:candle_frontend/features/comments/data/dio_comment_repository.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";

import "fake_comment_repository.dart";

void main() {
  late FakeCommentRepository repository;
  late ProviderContainer container;
  final provider = commentsControllerProvider(1);

  CommentsState state() => container.read(provider);
  CommentsController controller() => container.read(provider.notifier);
  List<String?> texts(Iterable<int> ids) => [for (final id in ids) state().comments[id]?.text];

  setUp(() {
    repository = FakeCommentRepository();
    container = ProviderContainer(
      overrides: [commentRepositoryProvider.overrideWithValue(repository)],
    );
    // Keep the auto-disposed controller alive for the whole test.
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    addTearDown(container.dispose);
  });

  test("top-level comments page newest first and skip duplicates", () async {
    for (final text in ["a", "b", "c"]) {
      repository.add(text);
    }
    await controller().refresh();
    expect(texts(state().top.ids), ["c", "b"]);
    expect(state().top.hasMore, isTrue);

    await controller().loadMore();
    expect(texts(state().top.ids), ["c", "b", "a"]);
    expect(state().top.hasMore, isFalse);

    final requests = repository.requests;
    await controller().loadMore();
    expect(repository.requests, requests, reason: "nothing left to load");
  });

  test("replies load on demand, oldest first, in pages, and collapse", () async {
    final root = repository.add("root");
    for (final text in ["r1", "r2", "r3"]) {
      repository.add(text, parent: root.id);
    }
    await controller().refresh();
    expect(state().comments[root.id]!.repliesCount, 3);
    expect(state().isExpanded(root.id), isFalse);

    await controller().showReplies(root.id);
    expect(state().isExpanded(root.id), isTrue);
    expect(texts(state().replies[root.id]!.ids), ["r1", "r2"]);

    await controller().loadMoreReplies(root.id);
    expect(texts(state().replies[root.id]!.ids), ["r1", "r2", "r3"]);

    controller().hideReplies(root.id);
    expect(state().isExpanded(root.id), isFalse);
    final requests = repository.requests;
    await controller().showReplies(root.id);
    expect(repository.requests, requests, reason: "loaded replies are kept");
  });

  test("posting adds a top-level comment first and a reply at the end of its branch", () async {
    final root = repository.add("root");
    repository.add("first reply", parent: root.id);
    await controller().refresh();

    expect(await controller().post("  hello  "), isTrue);
    expect(texts(state().top.ids), ["hello", "root"]);

    expect(await controller().post("my reply", parentCommentId: root.id), isTrue);
    expect(state().isExpanded(root.id), isTrue);
    expect(texts(state().replies[root.id]!.ids), ["first reply", "my reply"]);
    expect(state().comments[root.id]!.repliesCount, 2);

    final reply = state().replies[root.id]!.ids.last;
    expect(await controller().post("deeper", parentCommentId: reply), isTrue);
    expect(state().comments[reply]!.repliesCount, 1);
    expect(state().comments[root.id]!.repliesCount, 3, reason: "every ancestor counts it");
    expect(texts(state().replies[reply]!.ids), ["deeper"]);
  });

  test("a failed post changes nothing", () async {
    repository.add("root");
    await controller().refresh();
    repository.failCreate = true;
    expect(await controller().post("lost"), isFalse);
    expect(texts(state().top.ids), ["root"]);
  });

  test("deleting removes the comment with its whole branch", () async {
    final root = repository.add("root");
    final reply = repository.add("reply", parent: root.id);
    repository.add("deep", parent: reply.id);
    final other = repository.add("other");
    await controller().refresh();
    await controller().showReplies(root.id);
    await controller().showReplies(reply.id);
    expect(state().comments[root.id]!.repliesCount, 2);

    expect(await controller().delete(reply.id), isTrue);
    expect(state().replies[root.id]!.ids, isEmpty);
    expect(state().comments.containsKey(reply.id), isFalse);
    expect(state().replies.containsKey(reply.id), isFalse, reason: "the branch is dropped");
    expect(state().comments[root.id]!.repliesCount, 0);

    expect(await controller().delete(root.id), isTrue);
    expect(state().top.ids, [other.id]);

    repository.failDelete = true;
    expect(await controller().delete(other.id), isFalse);
    expect(state().top.ids, [other.id]);
  });

  test("a deleted account's comment stays as a placeholder until its replies are gone", () async {
    final root = repository.add("gone", authorId: 5, username: "gone");
    final reply = repository.add("mine", parent: root.id, authorId: 42, username: "me");
    repository.goneAuthors.add(5);
    await controller().refresh();
    final placeholder = state().comments[root.id]!;
    expect(placeholder.isDeleted, isTrue);
    expect(placeholder.text, isNull);
    await controller().showReplies(root.id);

    expect(await controller().delete(reply.id), isTrue);
    expect(state().top.ids, isEmpty, reason: "nothing live is left below the placeholder");
  });
}
