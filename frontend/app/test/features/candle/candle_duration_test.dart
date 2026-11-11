import "package:candle_frontend/features/candle/presentation/format_candle_duration.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  final ru = lookupAppLocalizations(const Locale("ru"));
  final en = lookupAppLocalizations(const Locale("en"));

  test("remaining duration switches units at day, hour and minute boundaries", () {
    expect(formatCandleDuration(const Duration(days: 30), ru), "30д 00:00:00");
    expect(formatCandleDuration(const Duration(days: 1), ru), "1д 00:00:00");
    expect(
      formatCandleDuration(const Duration(hours: 23, minutes: 59, seconds: 59), ru),
      "23:59:59",
    );
    expect(formatCandleDuration(const Duration(hours: 1), ru), "01:00:00");
    expect(formatCandleDuration(const Duration(minutes: 59, seconds: 59), ru), "00:59:59");
    expect(formatCandleDuration(const Duration(minutes: 1), ru), "00:01:00");
    expect(formatCandleDuration(const Duration(seconds: 59), ru), "00:00:59");
    expect(formatCandleDuration(Duration.zero, ru), "00:00:00");
    expect(formatCandleDuration(const Duration(seconds: -1), ru), "00:00:00");
  });

  test("English uses localized units and residual hours", () {
    expect(
      formatCandleDuration(const Duration(days: 29, hours: 23, minutes: 59, seconds: 12), en),
      "29d 23:59:12",
    );
  });
}
