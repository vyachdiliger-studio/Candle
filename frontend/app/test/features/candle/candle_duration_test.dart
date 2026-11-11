import "package:candle_frontend/features/candle/presentation/format_candle_duration.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("duration keeps all units at day, hour, minute and expiry boundaries", () {
    final cases = {
      const Duration(days: 30): (days: "30", hours: "00", minutes: "00", seconds: "00"),
      const Duration(days: 1): (days: "1", hours: "00", minutes: "00", seconds: "00"),
      const Duration(hours: 23, minutes: 59, seconds: 59): (
        days: "0",
        hours: "23",
        minutes: "59",
        seconds: "59",
      ),
      const Duration(hours: 1): (days: "0", hours: "01", minutes: "00", seconds: "00"),
      const Duration(minutes: 59, seconds: 59): (
        days: "0",
        hours: "00",
        minutes: "59",
        seconds: "59",
      ),
      const Duration(minutes: 1): (days: "0", hours: "00", minutes: "01", seconds: "00"),
      const Duration(seconds: 59): (days: "0", hours: "00", minutes: "00", seconds: "59"),
      Duration.zero: (days: "0", hours: "00", minutes: "00", seconds: "00"),
      const Duration(seconds: -1): (days: "0", hours: "00", minutes: "00", seconds: "00"),
      const Duration(days: 12345, hours: 21, minutes: 24, seconds: 13): (
        days: "12345",
        hours: "21",
        minutes: "24",
        seconds: "13",
      ),
    };
    for (final entry in cases.entries) {
      expect(formatCandleDuration(entry.key), entry.value);
    }
  });
}
