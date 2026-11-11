extension StringExtension on String {
  String? nullIfEmpty() => isEmpty ? null : this;

  String snakeToCamelCase() {
    if (isEmpty) return this;

    final parts = toLowerCase().split("_");

    return parts.first + parts.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join();
  }

  String camelToSnakeUpperCase() => replaceAllMapped(
    RegExp(r"[A-Z]"),
    (match) => "_${match.group(0)!.toLowerCase()}",
  ).replaceFirst("_", "").toUpperCase();
}

bool strIsEmpty(String s) => s.isEmpty;
bool strIsNotEmpty(String s) => s.isNotEmpty;
