import "package:flutter/widgets.dart";
import "../core/errors/app_failure.dart";
import "generated/app_localizations.dart";

export "generated/app_localizations.dart";

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension LocalizedFailure on AppLocalizations {
  String failure(AppFailure failure) => switch (failure) {
    AppFailure.accountUnavailable => accountUnavailable,
    AppFailure.connectionFailed => connectionFailed,
    AppFailure.credentialsChanged => credentialsChanged,
    AppFailure.currentPasswordRequired => currentPasswordRequired,
    AppFailure.googleTokenMissing => googleTokenMissing,
    AppFailure.imageDimensionsTooLarge => imageDimensionsTooLarge,
    AppFailure.imageOpenFailed => imageOpenFailed,
    AppFailure.imageTooLarge => imageTooLarge,
    AppFailure.incorrectPassword => incorrectPassword,
    AppFailure.invalidCredentials => invalidCredentials,
    AppFailure.invalidImage => invalidImage,
    AppFailure.invalidUsername => invalidUsername,
    AppFailure.loginFieldsRequired => loginFieldsRequired,
    AppFailure.passwordMismatch => passwordMismatch,
    AppFailure.passwordTooShort => passwordTooShort,
    AppFailure.policyRequired => policyRequired,
    AppFailure.recentCandlesFailed => recentCandlesFailed,
    AppFailure.requestFailed => requestFailed,
    AppFailure.telegramDataInvalid => telegramDataInvalid,
    AppFailure.telegramNotConfigured => telegramNotConfigured,
    AppFailure.telegramServerNotConfigured => telegramServerNotConfigured,
    AppFailure.telegramTimeout => telegramTimeout,
    AppFailure.telegramTokenInvalid => telegramTokenInvalid,
    AppFailure.telegramUnavailable => telegramUnavailable,
    AppFailure.tooManyAttempts => tooManyAttempts,
    AppFailure.unsupportedImage => unsupportedImage,
    AppFailure.uploadFailed => uploadFailed,
    AppFailure.uploadStalled => uploadStalled,
    AppFailure.usernameTaken => usernameTaken,
    AppFailure.candleNotLoaded => candleNotLoaded,
    AppFailure.backgroundSignInRequired => backgroundSignInRequired,
    AppFailure.backgroundAuthorOnly => backgroundAuthorOnly,
    AppFailure.backgroundSaveFailed => backgroundSaveFailed,
    AppFailure.telegramSdkUnavailable => telegramSdkUnavailable,
  };
}
