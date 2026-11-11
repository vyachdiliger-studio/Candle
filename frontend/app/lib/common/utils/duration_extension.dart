extension DurationFormatting on Duration {
  String get hms {
    final negativeSign = isNegative ? "-" : "";
    String twoDigits(int n) => n.abs().toString().padLeft(2, "0");
    final hours = twoDigits(inHours);
    final minutes = twoDigits(inMinutes.remainder(60));
    final seconds = twoDigits(inSeconds.remainder(60));
    return "$negativeSign$hours:$minutes:$seconds";
  }

  String get ms {
    final totalSeconds = (inMilliseconds / 1000).ceil();
    final negativeSign = isNegative ? "-" : "";
    String twoDigits(int n) => n.abs().toString().padLeft(2, "0");
    final minutes = twoDigits(totalSeconds ~/ 60);
    final seconds = twoDigits(totalSeconds % 60);
    return "$negativeSign$minutes:$seconds";
  }
}
