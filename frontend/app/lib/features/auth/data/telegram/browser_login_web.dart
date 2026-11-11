import "package:candle_frontend/core/errors/app_failure.dart";
import "dart:async";
import "dart:js_interop";

@JS("Telegram")
external _Telegram? get _telegram;

extension type _Telegram(JSObject _) implements JSObject {
  @JS("Login")
  external _Login? get login;
}

extension type _Login(JSObject _) implements JSObject {
  external JSFunction? get auth;
}

@JS("Telegram.Login.auth")
external void _telegramLoginAuth(
  _TelegramLoginOptions options,
  JSFunction callback,
);

extension type _TelegramLoginOptions._(JSObject _) implements JSObject {
  external factory _TelegramLoginOptions({
    @JS("client_id") required int clientId,
    JSArray<JSString>? scope,
  });
}

extension type _TelegramLoginResult._(JSObject _) implements JSObject {
  @JS("id_token")
  external String? get idToken;

  external String? get error;
}

Future<String?> loginWithTelegramWeb(String clientId) {
  final parsedClientId = int.tryParse(clientId);

  if (parsedClientId == null || parsedClientId <= 0) {
    throw ArgumentError.value(
      clientId,
      "clientId",
      "Invalid Telegram client ID.",
    );
  }

  if (_telegram?.login?.auth == null) {
    throw AppFailure.telegramSdkUnavailable;
  }

  final completer = Completer<String?>();

  void callback(_TelegramLoginResult? result) {
    if (completer.isCompleted) return;
    if (result == null || result.error == "popup_closed") {
      completer.complete(null);
      return;
    }
    final idToken = result.idToken;

    if (idToken != null && idToken.isNotEmpty) {
      completer.complete(idToken);
      return;
    }

    completer.completeError(
      AppFailure.telegramTokenInvalid,
    );
  }

  _telegramLoginAuth(
    _TelegramLoginOptions(
      clientId: parsedClientId,
      scope: ["profile".toJS].toJS,
    ),
    callback.toJS,
  );

  // Recover the button if the popup is closed without a callback or communication fails.
  final timer = Timer(const Duration(minutes: 2), () {
    if (!completer.isCompleted) {
      completer.completeError(TimeoutException("Telegram sign-in timed out. Please retry."));
    }
  });
  return completer.future.whenComplete(timer.cancel);
}
