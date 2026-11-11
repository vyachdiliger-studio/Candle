import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/l10n/localization.dart";
import "../application/language_controller.dart";

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(languageControllerProvider);
    final supported = AppLocalizations.supportedLocales;
    final selectedCode = supported.any((locale) => locale.toLanguageTag() == selected)
        ? selected
        : null;

    Future<void> select(String? languageCode) async {
      try {
        await ref.read(languageControllerProvider.notifier).select(languageCode);
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.languageSaveFailed)),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.all(Sizes.medium),
      children: [
        Padding(
          padding: const EdgeInsets.all(Sizes.medium),
          child: Text(context.l10n.language, style: Theme.of(context).textTheme.titleLarge),
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(context.l10n.systemLanguage),
          trailing: selectedCode == null ? const Icon(Icons.check) : null,
          selected: selectedCode == null,
          onTap: () => select(null),
        ),
        for (final locale in supported)
          ListTile(
            title: Text(lookupAppLocalizations(locale).languageName),
            trailing: selectedCode == locale.toLanguageTag() ? const Icon(Icons.check) : null,
            selected: selectedCode == locale.toLanguageTag(),
            onTap: () => select(locale.toLanguageTag()),
          ),
      ],
    );
  }
}
