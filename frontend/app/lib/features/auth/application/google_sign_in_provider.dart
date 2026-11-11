import "package:flutter/foundation.dart" show kIsWeb;
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:google_sign_in/google_sign_in.dart";

import "package:candle_frontend/core/config/app_config.dart";

final googleSignInProvider = FutureProvider<GoogleSignIn>((ref) async {
  final googleSignIn = GoogleSignIn.instance;

  if (kIsWeb) {
    await googleSignIn.initialize();
  } else {
    await googleSignIn.initialize(
      serverClientId: AppConfig.googleWebClientId,
    );
  }

  return googleSignIn;
});
