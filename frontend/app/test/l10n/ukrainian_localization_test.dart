import "dart:convert";
import "dart:io";

import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";

Set<String> _messageKeys(String path) {
  final json = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return json.keys.where((key) => !key.startsWith("@")).toSet();
}

void main() {
  test("Ukrainian ARB has exactly the template keys", () {
    final template = _messageKeys("lib/l10n/app_en.arb");
    final ukrainian = _messageKeys("lib/l10n/app_uk.arb");
    expect(template.difference(ukrainian), isEmpty, reason: "missing in app_uk.arb");
    expect(ukrainian.difference(template), isEmpty, reason: "extra in app_uk.arb");
  });

  test("Ukrainian is a supported locale with its own language name", () {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      contains("uk"),
    );
    expect(lookupAppLocalizations(const Locale("uk")).languageName, "Українська");
  });

  test("Ukrainian plurals use one, few and many forms", () {
    final l10n = lookupAppLocalizations(const Locale("uk"));
    expect(l10n.candleSupporters(0), "Поки ніхто не підтримав");
    expect(l10n.candleSupporters(1), "Підтримала 1 людина");
    expect(l10n.candleSupporters(2), "Підтримали 2 людини");
    expect(l10n.candleSupporters(5), "Підтримали 5 людей");
    expect(l10n.candleSupporters(21), "Підтримала 21 людина");
    expect(l10n.commentsCount(1), "1 коментар");
    expect(l10n.commentsCount(3), "3 коментарі");
    expect(l10n.commentsCount(11), "11 коментарів");
    expect(l10n.showReplies(22), "Показати 22 відповіді");
    expect(l10n.showReplies(25), "Показати 25 відповідей");
  });
}
