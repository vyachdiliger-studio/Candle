import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "package:candle_frontend/common/ui/widgets/app_update_menu.dart";
import "/core/constants/sizes.dart";
import "../application/login_controller.dart";
import "widgets/password_login_form.dart";
import "widgets/provider_login_buttons.dart";

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(loginControllerProvider.select((state) => state.error), (_, error) {
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.failure(error))));
      }
    });

    final accepted = ref.watch(loginControllerProvider.select((state) => state.policyAccepted));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sizes.large),
              child: ListView(
                children: [
                  const SizedBox(height: Sizes.extraLarge),
                  Text(
                    context.l10n.welcome,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: AppFontSizes.heading,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Sizes.small),
                  Text(
                    context.l10n.signInPrompt,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: AppFontSizes.body),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Sizes.large),
                  const _PrivacyConsent(),
                  const SizedBox(height: Sizes.medium),
                  AnimatedOpacity(
                    opacity: accepted ? 1 : AppEffects.unavailableOpacity,
                    duration: const Duration(milliseconds: 150),
                    child: AbsorbPointer(
                      absorbing: !accepted,
                      child: Column(
                        children: [
                          PasswordLoginForm(),
                          SizedBox(height: Sizes.large),
                          Text(context.l10n.or, textAlign: TextAlign.center),
                          SizedBox(height: Sizes.medium),
                          ProviderLoginButtons(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Sizes.extraLarge),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                tooltip: context.l10n.settings,
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.pushNamed("settings"),
              ),
            ),
            const Align(alignment: Alignment.topRight, child: AppUpdateMenu()),
          ],
        ),
      ),
    );
  }
}

class _PrivacyConsent extends ConsumerWidget {
  const _PrivacyConsent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: state.policyAccepted,
          onChanged: state.busy
              ? null
              : (value) => controller.policyAcceptedChanged(value ?? false),
        ),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(context.l10n.policyConsent, style: TextStyle(color: AppColors.textSecondary)),
              InkWell(
                onTap: () => context.push("/privacy"),
                child: Text(
                  context.l10n.policyConsentLink,
                  style: TextStyle(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
