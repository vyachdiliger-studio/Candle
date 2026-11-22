import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../application/app_build_info_provider.dart";
import "../domain/app_build_info.dart";

String _versionLabel(AppLocalizations l10n, AppBuildInfo info) => l10n.appBuildVersion(
  info.version.trim().isEmpty ? l10n.buildValueUnavailable : info.version,
  info.buildNumber.trim().isEmpty ? l10n.buildValueUnavailable : info.buildNumber,
);

class AppInfoTile extends ConsumerWidget {
  const AppInfoTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(appBuildInfoProvider);
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: Text(context.l10n.aboutCandle),
      subtitle: Text(
        info.when(
          data: (value) => _versionLabel(context.l10n, value),
          loading: () => context.l10n.buildInfoLoading,
          error: (_, _) => context.l10n.buildInfoUnavailable,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showDialog<void>(context: context, builder: (_) => const _AppInfoDialog()),
    );
  }
}

class _AppInfoDialog extends ConsumerWidget {
  const _AppInfoDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final info = ref.watch(appBuildInfoProvider);

    Future<void> copy(AppBuildInfo value) async {
      final text = [
        "Candle",
        _versionLabel(l10n, value),
        if (value.shortRevision != null) l10n.buildRevision(value.revision.trim()),
      ].join("\n");
      try {
        await Clipboard.setData(ClipboardData(text: text));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.copied)));
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.buildInfoCopyFailed)));
      }
    }

    return AlertDialog(
      title: Text(l10n.aboutCandle),
      scrollable: true,
      content: SizedBox(
        width: AppDimensions.dialog,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...info.when(
              data: (value) => <Widget>[
                SelectableText(_versionLabel(l10n, value)),
                const SizedBox(height: Sizes.small),
                SelectableText(
                  value.shortRevision == null
                      ? l10n.localBuild
                      : l10n.buildRevision(value.shortRevision!),
                ),
                const SizedBox(height: Sizes.small),
                TextButton.icon(
                  onPressed: () => copy(value),
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(l10n.copyBuildInfo),
                ),
              ],
              loading: () => <Widget>[
                const LinearProgressIndicator(),
                const SizedBox(height: Sizes.small),
                Text(l10n.buildInfoLoading),
              ],
              error: (_, _) => <Widget>[
                Text(l10n.buildInfoUnavailable),
                TextButton(
                  onPressed: () => ref.invalidate(appBuildInfoProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
            const Divider(height: Sizes.large),
            Text(l10n.whatsNew, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Sizes.small),
            Text(l10n.releaseNotesHint),
            const SizedBox(height: Sizes.medium),
            for (final entry in [
              (title: l10n.releaseCommentsTitle, body: l10n.releaseCommentsBody),
              (title: l10n.releaseCountdownTitle, body: l10n.releaseCountdownBody),
              (title: l10n.releaseLanguagesTitle, body: l10n.releaseLanguagesBody),
              (title: l10n.releaseAboutTitle, body: l10n.releaseAboutBody),
            ]) ...[
              Text(entry.title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: Sizes.extraSmall),
              Text(entry.body),
              const SizedBox(height: Sizes.medium),
            ],
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close))],
    );
  }
}
