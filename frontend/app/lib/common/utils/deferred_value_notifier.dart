import "dart:async";

class DeferredValueNotifier<T> {
  final _listeners = <Completer<T>>{};

  Future<T> get() {
    final completer = Completer<T>();

    _listeners.add(completer);

    return completer.future;
  }

  void set(T value) {
    _listeners
        .where((listener) => !listener.isCompleted)
        .forEach((listener) => listener.complete(value));

    _listeners.clear();
  }
}
