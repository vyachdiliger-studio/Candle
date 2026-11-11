import "package:candle_frontend/l10n/localization.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/core/platform/reload_app.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

enum _MenuAction { update }

/// A three-dot menu, web only, that reloads the app to fetch the latest build.
/// It needs no session, so it stays usable when sign-in itself is what broke.
class AppUpdateMenu extends HookWidget {
  const AppUpdateMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final reloading = useState(false);
    if (!kIsWeb) return const SizedBox.shrink();

    Future<void> update() async {
      reloading.value = true;
      try {
        await reloadApp();
      } catch (_) {
        if (!context.mounted) return;
        reloading.value = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.updateFailed)),
        );
      }
    }

    if (reloading.value) {
      return const Padding(
        padding: EdgeInsets.all(Sizes.regularPlus),
        child: SizedBox.square(
          dimension: Sizes.comfortable,
          child: CircularProgressIndicator(strokeWidth: AppStrokes.regular),
        ),
      );
    }
    return PopupMenuButton<_MenuAction>(
      tooltip: context.l10n.more,
      icon: const Icon(Icons.more_vert),
      onSelected: (_) => update(),
      itemBuilder: (_) => [
        PopupMenuItem<_MenuAction>(
          value: _MenuAction.update,
          child: ListTile(
            leading: Icon(Icons.system_update_alt),
            title: Text(context.l10n.updateApp),
            subtitle: Text(context.l10n.latestVersion),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
