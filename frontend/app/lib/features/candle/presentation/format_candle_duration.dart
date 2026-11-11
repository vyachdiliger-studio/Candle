import "package:candle_frontend/l10n/localization.dart";

String formatCandleDuration(Duration remaining, AppLocalizations l10n) {
  final left = remaining.isNegative ? Duration.zero : remaining;
  final days = left.inDays;
  final hours = left.inHours % Duration.hoursPerDay;
  final minutes = left.inMinutes % Duration.minutesPerHour;
  final seconds = left.inSeconds % Duration.secondsPerMinute;

  final time = [hours, minutes, seconds].map((value) => value.toString().padLeft(2, "0")).join(":");

  return days > 0 ? l10n.countdownDays(days, time) : time;
}
