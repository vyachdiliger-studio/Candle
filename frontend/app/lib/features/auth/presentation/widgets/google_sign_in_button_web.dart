import "package:flutter/material.dart";
import "package:google_sign_in_web/web_only.dart" as web;

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    required this.onPressed,
    super.key,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => web.renderButton(
    configuration: web.GSIButtonConfiguration(
      locale: Localizations.localeOf(context).toLanguageTag(),
    ),
  );
}
