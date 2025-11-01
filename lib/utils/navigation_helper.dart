import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Safe navigation helper to prevent "nothing to pop" errors
extension SafeNavigation on BuildContext {
  /// Safely pops the current route, or navigates to home if can't pop
  void safePop() {
    if (canPop()) {
      pop();
    } else {
      // If we can't pop and we're not on dashboard, go to dashboard
      // Otherwise, do nothing (prevent app from closing)
      final router = GoRouter.of(this);
      if (router.routerDelegate.currentConfiguration.uri.path != '/') {
        go('/');
      }
    }
  }
}

