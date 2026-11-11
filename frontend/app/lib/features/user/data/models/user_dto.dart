import "package:freezed_annotation/freezed_annotation.dart";

import "../../domain/models/user.dart";

part "user_dto.freezed.dart";
part "user_dto.g.dart";

@freezed
abstract class UserDto with _$UserDto {
  const UserDto._();

  const factory UserDto({
    required int id,
    required DateTime createdAt,
    String? username,
    @Default(false) bool hasPassword,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);

  User toDomain() =>
      User(id: id, createdAt: createdAt, username: username, hasPassword: hasPassword);

  static UserDto fromDomain(User user) => UserDto(
    id: user.id,
    createdAt: user.createdAt,
    username: user.username,
    hasPassword: user.hasPassword,
  );
}
