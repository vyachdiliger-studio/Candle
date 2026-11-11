import "../../../auth/application/auth_failure.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_riverpod/experimental/mutation.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../moderation/presentation/blocked_users_dialog.dart";
import "../../application/profile_controller.dart";
import "../../application/user_controller.dart";
import "../../application/user_mutations.dart";
import "../widgets/user_avatar.dart";
import "../widgets/profile_action_button.dart";
import "../widgets/profile_account_actions.dart";
import "../widgets/password_dialog.dart";

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);
    final user = ref.watch(userControllerProvider);

    final saving = ref.watch(saveProfileMutation);
    final deleting = ref.watch(deleteAccountMutation);

    final isBusy = saving is MutationPending || deleting is MutationPending;

    final error = switch ((saving, deleting)) {
      (MutationError(:final error), _) => context.l10n.failure(authFailure(error)),
      (_, MutationError(:final error)) => context.l10n.failure(authFailure(error)),
      _ => null,
    };

    final textController = useTextEditingController();

    // Follows the saved user, not the draft, so typing never moves the cursor.
    final saved = state.value?.original.username ?? "";

    useEffect(() {
      textController.text = saved;

      return null;
    }, [saved]);

    Future<void> confirmDelete() async {
      final isConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            context.l10n.deleteAccount,
            style: TextStyle(color: AppColors.primary),
          ),
          content: Text(
            context.l10n.deleteAccountWarning,
            style: TextStyle(color: AppColors.primary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                context.l10n.cancel,
                style: TextStyle(color: AppColors.primary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                context.l10n.delete,
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );

      if (isConfirmed != true) return;

      await deleteAccountMutation.run(
        ref,
        (_) => ref.read(userControllerProvider.notifier).deleteMe(),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: Sizes.large),
            children: [
              const SizedBox(height: Sizes.extraLarge),
              const Center(child: UserAvatar()),
              const SizedBox(height: Sizes.extraLarge),

              _UsernameField(
                controller: textController,
                onChanged: controller.usernameChanged,
                enabled: !isBusy,
              ),

              const SizedBox(height: Sizes.medium),
              Text(
                context.l10n.usernameHelp,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Sizes.large),
              ProfileActionButton(
                label: user.value?.hasPassword == true
                    ? context.l10n.changePassword
                    : context.l10n.setPassword,
                icon: Icons.lock_outline,
                onTap: isBusy || user.isLoading || user.hasError
                    ? null
                    : () async {
                        final saved = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => PasswordDialog(hasPassword: user.value!.hasPassword),
                        );
                        if (saved == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.l10n.passwordSaved,
                              ),
                            ),
                          );
                        }
                      },
              ),
              const SizedBox(height: Sizes.large),
              ProfileActionButton(
                label: context.l10n.blockedAuthors,
                icon: Icons.block_outlined,
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => const BlockedUsersDialog(),
                ),
              ),
              const SizedBox(height: Sizes.large),
              ProfileActionButton(
                label: context.l10n.privacyPolicy,
                icon: Icons.privacy_tip_outlined,
                onTap: () => context.push("/privacy"),
              ),
              const SizedBox(height: Sizes.large),
              if (error != null) _ErrorBanner(message: error),
              const SizedBox(height: Sizes.extraLarge),

              if (state.value?.isDirty ?? false)
                Padding(
                  padding: const EdgeInsets.only(bottom: Sizes.medium),
                  child: ProfileActionButton(
                    label: context.l10n.save,
                    icon: Icons.check,
                    onTap: isBusy
                        ? null
                        : () => saveProfileMutation.run(
                            ref,
                            (_) => controller.save(),
                          ),
                  ),
                ),

              ProfileAccountActions(
                onLogout: isBusy ? null : controller.logout,
                onDelete: isBusy ? null : confirmDelete,
              ),

              const SizedBox(height: Sizes.mega),
            ],
          ),
        ),
        if (isBusy)
          const Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(
              minHeight: Sizes.tiny,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }
}

class _UsernameField extends StatelessWidget {
  const _UsernameField({
    required this.controller,
    required this.onChanged,
    required this.enabled,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: AppFontSizes.titleLarge,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: context.l10n.username,
        hintStyle: TextStyle(
          color: AppColors.inputHint,
          fontSize: AppFontSizes.titleLarge,
        ),
        filled: true,
        fillColor: AppColors.inputSurface,
        contentPadding: const EdgeInsets.symmetric(
          vertical: Sizes.medium,
          horizontal: Sizes.medium,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.controlOutline,
            width: Sizes.hairline,
          ),
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary, width: AppStrokes.focused),
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.large,
        vertical: Sizes.medium,
      ),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(AppRadii.large),
        border: Border.all(
          color: AppColors.errorOutline,
          width: Sizes.hairline,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: Sizes.medium),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: Sizes.medium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
