import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "/core/constants/sizes.dart";
import "../../application/login_controller.dart";

class PasswordLoginForm extends ConsumerWidget {
  const PasswordLoginForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: controller.usernameChanged,
            enabled: !state.busy,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.username],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: context.l10n.username),
          ),
          TextField(
            onChanged: controller.passwordChanged,
            enabled: !state.busy,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => controller.loginWithPassword(),
            decoration: InputDecoration(
              labelText: context.l10n.password,
              helperText: context.l10n.passwordHint,
            ),
          ),
          if (state.passwordError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sizes.small),
              child: Text(
                context.l10n.failure(state.passwordError!),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          const SizedBox(height: Sizes.medium),
          FilledButton(
            onPressed: state.busy ? null : controller.loginWithPassword,
            child: state.pending == LoginMethod.password
                ? const SizedBox(
                    width: Sizes.mediumPlus,
                    height: Sizes.mediumPlus,
                    child: CircularProgressIndicator(strokeWidth: AppStrokes.regular),
                  )
                : Text(context.l10n.continueAction),
          ),
          Text(
            context.l10n.passwordLoginHelp,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
