import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:sign_in_button/sign_in_button.dart";

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    required this.onPressed,
    super.key,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SignInButton(
    Buttons.google,
    text: context.l10n.googleSignIn,
    onPressed: onPressed,
  );
}
