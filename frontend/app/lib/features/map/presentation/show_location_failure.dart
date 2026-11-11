import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "../../../core/location/location_controller.dart";
import "../../../core/location/location_service.dart";
import "../../../l10n/localization.dart";

Future<void> showLocationFailure(BuildContext context, WidgetRef ref) async {
  final error = ref.read(locationControllerProvider).error;
  final service = ref.read(locationServiceProvider);
  final failure = error is LocationFailure ? error : LocationFailure.unavailable;
  final settingsNeeded =
      failure == LocationFailure.blocked || failure == LocationFailure.servicesDisabled;
  final message = switch (failure) {
    LocationFailure.denied => context.l10n.locationDenied,
    LocationFailure.blocked =>
      service.canOpenSettings ? context.l10n.locationBlocked : context.l10n.locationBrowserBlocked,
    LocationFailure.clientUnavailable => context.l10n.locationClientUnavailable,
    LocationFailure.servicesDisabled => context.l10n.locationDisabled,
    LocationFailure.initializationFailed => context.l10n.locationInitializationFailed,
    LocationFailure.timeout => context.l10n.locationTimeout,
    LocationFailure.unavailable => context.l10n.locationUnavailable,
  };
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.myLocation),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(context.l10n.cancel)),
        if (settingsNeeded && service.canOpenSettings)
          TextButton(
            onPressed: () async {
              // Telegram requires opening settings directly from the button gesture.
              try {
                final opened = service.openSettings(failure);
                Navigator.pop(dialogContext);
                if (!await opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.locationSettingsFailed)),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.locationSettingsFailed)),
                  );
                }
              }
            },
            child: Text(context.l10n.settings),
          ),
      ],
    ),
  );
}
