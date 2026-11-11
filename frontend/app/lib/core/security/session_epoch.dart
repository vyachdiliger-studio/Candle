import "package:flutter_riverpod/flutter_riverpod.dart";

/// Identifies a login lifetime, including when the same user logs in again.
final sessionEpochProvider = NotifierProvider<SessionEpoch, int>(SessionEpoch.new);

class SessionEpoch extends Notifier<int> {
  @override
  int build() => 0;
  int get current => state;
  int advance() => state = state + 1;
}

class SessionChanged implements Exception {
  const SessionChanged();
  @override
  String toString() => "Session changed";
}
