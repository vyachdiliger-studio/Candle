import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "/core/constants/sizes.dart";
import "../../application/login_controller.dart";
import "google_sign_in_button.dart";

class ProviderLoginButtons extends ConsumerWidget {
  const ProviderLoginButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    return Column(
      children: [
        if (controller.telegramAvailable) ...[
          SizedBox(
            width: AppDimensions.providerButtonWidth,
            height: AppDimensions.extraComfortable,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onTelegram,
                backgroundColor: AppColors.telegramSurface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.small)),
              ),
              onPressed: state.busy ? null : controller.loginWithTelegram,
              icon: const Icon(Icons.send, size: Sizes.comfortable),
              label: Text(
                state.pending == LoginMethod.telegram
                    ? context.l10n.signingIn
                    : context.l10n.telegramSignIn,
              ),
            ),
          ),
          if (controller.isMiniApp)
            Padding(
              padding: EdgeInsets.only(top: Sizes.small),
              child: Text(
                context.l10n.telegramAccountHelp,
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: Sizes.small),
        ],
        AbsorbPointer(
          absorbing: state.busy,
          child: GoogleSignInButton(onPressed: controller.loginWithGoogle),
        ),
      ],
    );
  }
}
