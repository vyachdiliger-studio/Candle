({String days, String hours, String minutes, String seconds}) formatCandleDuration(
  Duration remaining,
) {
  final left = remaining.isNegative ? Duration.zero : remaining;
  final days = left.inDays;
  final hours = left.inHours % Duration.hoursPerDay;
  final minutes = left.inMinutes % Duration.minutesPerHour;
  final seconds = left.inSeconds % Duration.secondsPerMinute;

  return (
    days: days.toString(),
    hours: hours.toString().padLeft(2, "0"),
    minutes: minutes.toString().padLeft(2, "0"),
    seconds: seconds.toString().padLeft(2, "0"),
  );
}
