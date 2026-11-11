import "dart:js_interop";

@JS("Telegram")
external _Telegram? get _telegram;

extension type _Telegram(JSObject _) implements JSObject {
  @JS("WebApp")
  external _WebApp? get webApp;
}

extension type _WebApp(JSObject _) implements JSObject {
  external String? get initData;
}

// The SDK captures launch data before Flutter changes the URL.
String get telegramInitData => _telegram?.webApp?.initData ?? "";
