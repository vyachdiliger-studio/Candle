import "package:flutter/material.dart";

import "../../../../core/constants/sizes.dart";
import "../../../../l10n/localization.dart";
import "profile_action_button.dart";

class ProfileAccountActions extends StatelessWidget {
  const ProfileAccountActions({super.key, required this.onLogout, required this.onDelete});

  final VoidCallback? onLogout;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final logout = ProfileActionButton(
      label: context.l10n.logout,
      icon: Icons.logout,
      onTap: onLogout,
    );
    final delete = ProfileActionButton(
      label: context.l10n.deleteAccount,
      icon: Icons.delete_outline,
      onTap: onDelete,
      danger: true,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth = (constraints.maxWidth - Sizes.medium) / 2;
        final fits =
            logout.minimumWidth(context) <= buttonWidth &&
            delete.minimumWidth(context) <= buttonWidth;

        if (fits) {
          return Row(
            children: [
              Expanded(child: logout),
              const SizedBox(width: Sizes.medium),
              Expanded(child: delete),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            logout,
            const SizedBox(height: Sizes.medium),
            delete,
          ],
        );
      },
    );
  }
}
