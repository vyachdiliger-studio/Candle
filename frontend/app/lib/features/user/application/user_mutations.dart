import "package:flutter_riverpod/experimental/mutation.dart";

import "../domain/models/user.dart";

final saveProfileMutation = Mutation<User>(label: "saveProfile");

final deleteAccountMutation = Mutation<void>(label: "deleteAccount");
