import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class KairosCard extends StatelessWidget {
  const KairosCard({
    required this.child,
    this.padding = const EdgeInsets.all(KairosSpacing.md),
    this.color,
    this.borderColor,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(KairosRadius.md);
    final fallbackFill = theme.colorScheme.surface.withValues(
      alpha: isDark ? 0.3 : 0.58,
    );
    final glassFill =
        color?.withValues(alpha: isDark ? 0.32 : 0.54) ?? fallbackFill;
    final glassBorder = borderColor?.withValues(alpha: isDark ? 0.42 : 0.5) ??
        (isDark
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.78));

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.72),
            blurRadius: 6,
            offset: const Offset(-1, -1),
          ),
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF29476A))
                .withValues(alpha: isDark ? 0.34 : 0.1),
            blurRadius: 42,
            spreadRadius: -18,
            offset: const Offset(0, 28),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withValues(
              alpha: isDark ? 0.1 : 0.07,
            ),
            blurRadius: 22,
            spreadRadius: -14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: glassFill,
              borderRadius: radius,
              border: Border.all(color: glassBorder),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.13 : 0.82),
                  glassFill,
                  (isDark ? const Color(0xFF161B22) : const Color(0xFFEAF6FF))
                      .withValues(alpha: isDark ? 0.18 : 0.34),
                ],
                stops: const [0, 0.5, 1],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        child: content,
      ),
    );
  }
}
