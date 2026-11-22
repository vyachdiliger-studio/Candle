# Localization

User-facing copy lives in `app_en.arb`, `app_ru.arb`, `app_uk.arb` and `app_th.arb`. English is the template
and the fallback for unsupported device languages. User content, API values,
URLs and diagnostic logs are not translation keys.

Run `flutter gen-l10n` after editing an ARB file. The generated Dart sources in
`generated/` are ignored by Git; Flutter also generates them during builds.

In widgets, import `localization.dart` and use `context.l10n.save` or a generated
method such as `context.l10n.candleNumber(id)`. Use ARB placeholders and ICU
plural forms for variable text, rather than concatenating translated fragments.

Application and data layers do not depend on localization or BuildContext.
They expose `AppFailure` values, which the UI translates with
`context.l10n.failure(failure)`. Sharing receives the localized invitation and
subject explicitly from presentation.

Settings persists a locale tag locally, independently of the account. A null
selection follows the device language. The saved preference is read before the
app starts; later changes rebuild localizations without recreating the router
or feature controllers. Synchronizing this preference with the Telegram bot or
backend is a separate concern.

To add a language, add `app_<locale>.arb` with all template keys and a
`languageName` written in that language, then regenerate. Settings enumerates
`AppLocalizations.supportedLocales` automatically. Also list the new language
under `CFBundleLocalizations` in `ios/Runner/Info.plist`.