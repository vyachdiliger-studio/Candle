import "package:freezed_annotation/freezed_annotation.dart";

import "../domain/models/user.dart";

part "profile_state.freezed.dart";

@freezed
abstract class ProfileState with _$ProfileState {
  const ProfileState._();

  /// The form is a draft of the user beside the version it started from, so a
  /// new editable field costs one field on [User] and nothing here - no second
  /// "original" copy and no per-field dirty flag.
  const factory ProfileState({required User original, required User draft}) = _ProfileState;

  bool get isDirty => draft != original;
}
