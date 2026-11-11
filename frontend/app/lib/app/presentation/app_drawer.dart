import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/core/platform/reload_app.dart";
import "package:candle_frontend/features/user/user.dart";
import "package:candle_frontend/features/user/presentation/widgets/user_avatar.dart";
import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userControllerProvider);
    final user = userState.isLoading || userState.hasError ? null : userState.value;

    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(Sizes.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const UserAvatar(size: AppDimensions.avatarCompact),
                  const SizedBox(height: Sizes.medium),
                  Text(
                    user?.username ?? context.l10n.noUsername,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: user?.username == null
                          ? AppColors.textPlaceholder
                          : AppColors.textPrimary,
                      fontSize: AppFontSizes.title,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.controlSurface, height: Sizes.hairline),
            _DrawerItem(
              icon: Icons.person_outline,
              label: context.l10n.profile,
              onTap: () {
                Navigator.pop(context);

                context.pushNamed("profile");
              },
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: context.l10n.settings,
              onTap: () {
                Navigator.pop(context);
                context.pushNamed("settings");
              },
            ),
            const Spacer(),
            if (kIsWeb) const _ReloadButton(),
          ],
        ),
      ),
    );
  }
}

class _ReloadButton extends StatefulWidget {
  const _ReloadButton();

  @override
  State<_ReloadButton> createState() => _ReloadButtonState();
}

class _ReloadButtonState extends State<_ReloadButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.destructive,
    child: ListTile(
      leading: Icon(Icons.refresh, color: AppColors.primary),
      title: Text(
        _busy ? context.l10n.reloading : context.l10n.reloadApp,
        style: const TextStyle(color: AppColors.primary),
      ),
      subtitle: Text(
        context.l10n.unsavedChanges,
        style: TextStyle(color: AppColors.primary),
      ),
      enabled: !_busy,
      onTap: () async {
        setState(() => _busy = true);
        try {
          await reloadApp();
        } catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.reloadFailed),
            ),
          );
          setState(() => _busy = false);
        }
      },
    ),
  );
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final void Function() onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Sizes.large,
          vertical: Sizes.medium,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: Sizes.generous),
            const SizedBox(width: Sizes.medium),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: AppFontSizes.body,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
