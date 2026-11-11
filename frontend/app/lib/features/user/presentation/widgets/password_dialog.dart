import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../application/password_form_controller.dart";

class PasswordDialog extends ConsumerWidget {
  const PasswordDialog({super.key, required this.hasPassword});

  final bool hasPassword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = passwordFormControllerProvider(hasPassword);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    ref.listen(provider.select((value) => value.saved), (_, saved) {
      if (saved) Navigator.of(context).pop(true);
    });

    return PopScope(
      canPop: !state.busy,
      child: AlertDialog(
        title: Text(hasPassword ? context.l10n.changePassword : context.l10n.setPassword),
        content: SingleChildScrollView(
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasPassword)
                  TextField(
                    onChanged: controller.currentPasswordChanged,
                    enabled: !state.busy,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: context.l10n.currentPassword),
                  ),
                TextField(
                  onChanged: controller.passwordChanged,
                  enabled: !state.busy,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: context.l10n.newPassword,
                    helperText: context.l10n.passwordHint,
                  ),
                ),
                TextField(
                  onChanged: controller.confirmationChanged,
                  enabled: !state.busy,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => controller.save(),
                  decoration: InputDecoration(labelText: context.l10n.confirmPassword),
                ),
                if (state.busy) const LinearProgressIndicator(),
                if (state.error != null)
                  Text(
                    context.l10n.failure(state.error!),
                    style: const TextStyle(color: AppColors.error),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: state.busy ? null : () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: state.busy ? null : controller.save,
            child: Text(context.l10n.savePassword),
          ),
        ],
      ),
    );
  }
}
