import "dart:js_interop";

@JS("candleReloadApp")
external JSPromise<JSAny?> _reloadApp();

Future<void> reloadApp() async => await _reloadApp().toDart;
