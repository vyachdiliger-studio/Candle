import "package:flutter_riverpod/experimental/mutation.dart";

import "package:candle_frontend/features/candle/candle.dart";

/// Placing a candle is an action, not a piece of the map's data, so its pending
/// and error states live here rather than in a controller - a mutation resets
/// itself once nothing listens, which a field on the state never would.
final saveCandleLocationMutation = Mutation<Candle>(
  label: "saveCandleLocation",
);
