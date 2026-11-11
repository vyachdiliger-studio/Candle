extension Tuple2Extension<T1, T2> on (T1, T2) {
  R unpack<R>(R Function(T1, T2) func) => func(this.$1, this.$2);
}
