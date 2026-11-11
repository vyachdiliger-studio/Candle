extension NullableExtension<T> on T? {
  bool get isNull => _isNull(this);
  bool get isNotNull => _isNotNull(this);

  R mapIfNull<R>(
    R Function(T value) ifNotNull, {
    required R Function() ifNull,
  }) => isNull ? ifNull() : ifNotNull(this as T);
}

final _isNull = isNull;
final _isNotNull = isNotNull;

bool isNull(Object? obj) => obj == null;
bool isNotNull(Object? obj) => obj != null;
