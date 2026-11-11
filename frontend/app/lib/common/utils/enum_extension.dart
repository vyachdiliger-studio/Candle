extension EnumExtension<T extends Enum> on Iterable<T> {
  T? byNameOrNull(String name) {
    for (var value in this) {
      if (value.name == name) return value;
    }

    return null;
  }
}
