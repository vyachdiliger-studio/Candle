import "package:flutter/material.dart";

extension TimeOfDayComparison on TimeOfDay {
  bool operator <(TimeOfDay other) {
    return hour < other.hour || (hour == other.hour && minute < other.minute);
  }

  bool operator >(TimeOfDay other) {
    return hour > other.hour || (hour == other.hour && minute > other.minute);
  }

  bool operator <=(TimeOfDay other) {
    return this < other || _isSameAs(other);
  }

  bool operator >=(TimeOfDay other) {
    return this > other || _isSameAs(other);
  }

  bool isBetween(TimeOfDay start, TimeOfDay end) {
    return (this >= start && this <= end);
  }

  int compareTo(TimeOfDay other) {
    if (this < other) return -1;
    if (this > other) return 1;
    return 0;
  }

  bool _isSameAs(TimeOfDay other) {
    return hour == other.hour && minute == other.minute;
  }
}
