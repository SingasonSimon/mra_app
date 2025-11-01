import 'package:flutter/material.dart';
import '../app/theme/app_theme.dart';

/// Helper class for theme-aware colors and styling
class ThemeColors {
  static Color getBackground(BuildContext context) {
    return Theme.of(context).colorScheme.background;
  }

  static Color getSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1F2937) // gray-800
        : AppTheme.white;
  }

  static Color getCardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1F2937)
        : AppTheme.white;
  }

  static Color getCardBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.gray700
        : AppTheme.gray200;
  }

  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.white.withValues(alpha: 0.9)
        : AppTheme.gray900;
  }

  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.white.withValues(alpha: 0.6)
        : AppTheme.gray600;
  }

  static Color getTextTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.white.withValues(alpha: 0.6)
        : AppTheme.gray500;
  }

  static LinearGradient getHeaderGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F2937), Color(0xFF111827)],
          )
        : AppTheme.tealGradient;
  }

  static LinearGradient getRedGradient() {
    return AppTheme.redGradient;
  }
}

/// Themed card widget
class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const ThemedCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeColors.getCardBorder(context),
          width: 1,
        ),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: padding != null
              ? Padding(padding: padding!, child: child)
              : child,
        ),
      ),
    );
  }
}

/// Themed header container with gradient
class ThemedHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showGradient;

  const ThemedHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.showGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = showGradient
        ? ThemeColors.getHeaderGradient(context)
        : LinearGradient(colors: [ThemeColors.getSurface(context), ThemeColors.getSurface(context)]);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (leading != null) leading!,
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}

