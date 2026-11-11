import "package:freezed_annotation/freezed_annotation.dart";

part "user.freezed.dart";

@freezed
abstract class User with _$User {
  const factory User({
    required int id,
    required DateTime createdAt,
    String? username,
    @Default(false) bool hasPassword,
  }) = _User;
}
