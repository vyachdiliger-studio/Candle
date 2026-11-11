import "package:candle_frontend/core/constants/app_colors.dart";
import "package:candle_frontend/features/user/user.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "app_drawer.dart";

/// Owns the app's only Scaffold, and with it the drawer.
///
/// It sits above the navigator the pages live in, so opening a page never
/// covers the drawer - which is what lets the drawer close the ordinary way,
/// animation and all, instead of freezing half way under the new route.
class DrawerShell extends ConsumerWidget {
  final Widget child;

  const DrawerShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Warms the user for the whole session: it is kept alive, so this one read
    // is what makes it load at startup rather than when a screen first asks.
    ref.watch(userControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: const AppDrawer(),
      body: child,
    );
  }
}
