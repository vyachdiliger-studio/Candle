import "package:dartz/dartz.dart";

extension EitherExtension<L, R> on Either<L, R> {
  R asRight() => (this as Right).value;
  L asLeft() => (this as Left).value;
  R getRight() => fold((l) => null, (r) => r) as R;
  L getLeft() => fold((l) => l, (r) => null) as L;
  R? rightOrNull() => fold((l) => null, (r) => r);
}
