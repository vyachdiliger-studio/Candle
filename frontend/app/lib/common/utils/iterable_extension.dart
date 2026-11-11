import "dart:math";

extension IterableExtension<T> on Iterable<T> {
  Iterable<T> insertBetween(T item) {
    return isEmpty ? this : (expand((element) => [element, item]).toList()..removeLast());
  }

  T? minByOrNull<C extends Comparable>(C Function(T item) selector) {
    if (isEmpty) return null;

    return reduce((a, b) => selector(a).compareTo(selector(b)) <= 0 ? a : b);
  }

  R sumBy<R extends num>(R Function(T item) selector) =>
      fold<R>(0 as R, (sum, item) => (sum + selector(item)) as R);

  Iterable<(int index, T item)> enumerate() sync* {
    var index = 0;

    for (var item in this) {
      yield (index++, item);
    }
  }

  Iterable<List<T>> chunked(int size) sync* {
    final items = toList();

    for (var start = 0; start < items.length; start += size) {
      yield items.sublist(start, min(start + size, items.length));
    }
  }

  Iterable<T>? nullIfEmpty() => isEmpty ? null : this;
}
