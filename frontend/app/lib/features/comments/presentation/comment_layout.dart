import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/widgets.dart";
import "package:intl/intl.dart";

abstract final class CommentLayout {
  /// How many reply levels are indented inside one list. Deeper replies open as a
  /// focused branch ("View thread"), as in Threads. Threads does not document its
  /// exact limit; two levels keep a branch readable in a two-thirds-height sheet.
  static const maxInlineDepth = 2;

  static const double avatar = Sizes.spacious;
  static const double indent = Sizes.spacious;

  /// Initial and full sheet height as a share of the available height.
  static const double sheetHeight = 2 / 3;
  static const double fullHeight = 1;

  /// Dragging the sheet below this share closes it.
  static const double closeBelow = 0.45;

  /// A downward fling faster than this (logical pixels per second) closes the sheet;
  /// an upward one faster than a third of it expands the sheet.
  static const double flingVelocity = 1500;

  /// Room the list keeps above the keyboard.
  static const double minListHeight = 280;
}

/// "now", "5 min", "3 h", "2 d", then a date.
String formatCommentAge(BuildContext context, DateTime createdAt, DateTime now) {
  final age = now.difference(createdAt);
  final l10n = context.l10n;
  if (age.inMinutes < 1) return l10n.timeNow;
  if (age.inHours < 1) return l10n.timeMinutes(age.inMinutes);
  if (age.inDays < 1) return l10n.timeHours(age.inHours);
  if (age.inDays < 7) return l10n.timeDays(age.inDays);
  return DateFormat.yMMMd(l10n.localeName).format(createdAt.toLocal());
}
