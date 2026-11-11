import "package:candle_frontend/core/errors/app_failure.dart";
import "package:dio/dio.dart";

AppFailure authFailure(Object error) {
  if (error is! DioException) return AppFailure.requestFailed;
  if (error.response?.statusCode == 429) return AppFailure.tooManyAttempts;
  return switch (error.response?.data) {
    "invalid_telegram_data" => AppFailure.telegramDataInvalid,
    "invalid_telegram_token" => AppFailure.telegramTokenInvalid,
    "telegram_unavailable" => AppFailure.telegramUnavailable,
    "telegram_not_configured" => AppFailure.telegramServerNotConfigured,
    "account_unavailable" => AppFailure.accountUnavailable,
    "invalid_credentials" => AppFailure.invalidCredentials,
    "invalid_username" => AppFailure.invalidUsername,
    "invalid_password_length" => AppFailure.passwordTooShort,
    "incorrect_current_password" => AppFailure.incorrectPassword,
    "username_taken" => AppFailure.usernameTaken,
    "credentials_changed" => AppFailure.credentialsChanged,
    _ => error.response == null ? AppFailure.connectionFailed : AppFailure.requestFailed,
  };
}
