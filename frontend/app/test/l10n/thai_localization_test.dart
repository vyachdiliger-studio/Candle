import "dart:convert";
import "dart:io";

import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";

Map<String, String> _messages(String path) {
  final json = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final entry in json.entries)
      if (!entry.key.startsWith("@")) entry.key: entry.value as String,
  };
}

Set<String> _placeholders(String message) =>
    RegExp(r"\{(\w+)[,}]").allMatches(message).map((match) => match.group(1)!).toSet();

void main() {
  final template = _messages("lib/l10n/app_en.arb");
  final thai = _messages("lib/l10n/app_th.arb");

  test("Thai ARB has exactly the template keys", () {
    expect(
      template.keys.toSet().difference(thai.keys.toSet()),
      isEmpty,
      reason: "missing in app_th.arb",
    );
    expect(
      thai.keys.toSet().difference(template.keys.toSet()),
      isEmpty,
      reason: "extra in app_th.arb",
    );
  });

  test("Thai messages keep the template placeholders", () {
    for (final key in template.keys) {
      expect(_placeholders(thai[key]!), _placeholders(template[key]!), reason: key);
    }
  });

  test("Thai UI copy has no gendered polite particles", () {
    for (final entry in thai.entries) {
      expect(entry.value, isNot(matches(RegExp("ครับ|ค่ะ|คะ"))), reason: entry.key);
    }
  });

  test("Thai is a supported locale with its own language name", () {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      contains("th"),
    );
    expect(lookupAppLocalizations(const Locale("th")).languageName, "ไทย");
  });

  test("Thai counts use a single form after numbers", () {
    final l10n = lookupAppLocalizations(const Locale("th"));
    expect(l10n.candleSupporters(0), "ยังไม่มีผู้ร่วมส่งกำลังใจ");
    expect(l10n.candleSupporters(1), "มีผู้ร่วมส่งกำลังใจ 1 คน");
    expect(l10n.candleSupporters(21), "มีผู้ร่วมส่งกำลังใจ 21 คน");
    expect(l10n.commentsCount(0), "ยังไม่มีความคิดเห็น");
    expect(l10n.commentsCount(1), "1 ความคิดเห็น");
    expect(l10n.commentsCount(5), "5 ความคิดเห็น");
    expect(l10n.showReplies(1), "ดูการตอบกลับ 1 รายการ");
    expect(l10n.showReplies(22), "ดูการตอบกลับ 22 รายการ");
    expect(
      l10n.deleteCommentWithReplies(3),
      "ลบความคิดเห็นนี้และการตอบกลับ 3 รายการหรือไม่ การดำเนินการนี้ไม่สามารถย้อนกลับได้",
    );
  });
}
