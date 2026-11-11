extension CollectionExtension<T extends Iterable> on T {
  T? nullIfEmpty() => isEmpty ? null : this;
}
