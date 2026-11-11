import "package:flutter/foundation.dart";
import "package:flutter_hooks/flutter_hooks.dart";

ValueNotifier<int> useFrameTicker({required bool enabled}) {
  final vsync = useSingleTickerProvider();
  // useState would rebuild the whole widget on every frame, which defeats the
  // ValueListenableBuilder callers wrap this in - and tears down anything
  // mid-flight in that subtree, gestures included.
  final frame = useValueNotifier<int>(0);

  final ticker = useMemoized(() => vsync.createTicker((_) => frame.value++), [
    vsync,
  ]);

  useEffect(() {
    if (enabled) {
      if (!ticker.isActive) ticker.start();
    } else {
      if (ticker.isActive) ticker.stop();
    }
    return null;
  }, [enabled, ticker]);

  useEffect(() => ticker.dispose, [ticker]);

  return frame;
}
