import "dart:js_interop";

@JS("Telegram")
external _Telegram? get _telegram;

extension type _Telegram(JSObject _) implements JSObject {
  @JS("WebApp")
  external _WebApp? get webApp;
}

extension type _WebApp(JSObject _) implements JSObject {
  external String? get initData;
  external bool isVersionAtLeast(String version);
  @JS("HapticFeedback")
  external _Haptics? get haptics;
  external void openTelegramLink(String url);
}

/// Only a launch from Telegram carries launch data; the SDK script alone is
/// present in every browser.
bool get isTelegramMiniApp => (_telegram?.webApp?.initData ?? "").isNotEmpty;

/// Opens a t.me link inside Telegram, keeping the Mini App open. Returns false
/// when the client can't.
bool openTelegramLink(String url) {
  try {
    _telegram!.webApp!.openTelegramLink(url);
    return true;
  } catch (_) {
    return false;
  }
}

extension type _Haptics(JSObject _) implements JSObject {
  external void impactOccurred(String style);
}

bool telegramTapHaptic() {
  try {
    final app = _telegram?.webApp;
    if (!isTelegramMiniApp || app == null || !app.isVersionAtLeast("6.1")) return false;
    final haptics = app.haptics;
    if (haptics == null) return false;
    haptics.impactOccurred("light");
    return true;
  } catch (_) {
    return false;
  }
}
