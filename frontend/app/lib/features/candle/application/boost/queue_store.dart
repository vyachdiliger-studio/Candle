abstract interface class BoostQueueStore {
  Future<Map<int, int>> loadPending();
  Future<void> savePending(Map<int, int> pending);
}

class NoopBoostQueueStore implements BoostQueueStore {
  @override
  Future<Map<int, int>> loadPending() async => {};

  @override
  Future<void> savePending(Map<int, int> pending) async {}
}
