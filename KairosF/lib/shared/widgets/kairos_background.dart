import 'package:flutter/material.dart';

class KairosBackground extends StatelessWidget {
  const KairosBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlay = isDark ? Colors.black : Colors.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.75, -0.9),
          radius: 1.65,
          colors: isDark
              ? const [
                  Color(0xFF2A2544),
                  Color(0xFF101B22),
                  Color(0xFF07090D),
                  Color(0xFF15100F),
                ]
              : const [
                  Color(0xFFFFFFFF),
                  Color(0xFFEFF8FA),
                  Color(0xFFF6F0FF),
                  Color(0xFFFFF7ED),
                ],
          stops: const [0, 0.34, 0.72, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.06 : 0.62),
                  Colors.transparent,
                  const Color(0xFF2DD4BF).withValues(
                    alpha: isDark ? 0.06 : 0.16,
                  ),
                ],
                stops: const [0, 0.48, 1],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  const Color(0xFFFACC15).withValues(
                    alpha: isDark ? 0.05 : 0.18,
                  ),
                  Colors.transparent,
                  const Color(0xFFFF6B6B).withValues(
                    alpha: isDark ? 0.05 : 0.14,
                  ),
                ],
                stops: const [0, 0.54, 1],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  overlay.withValues(alpha: isDark ? 0.12 : 0.04),
                  overlay.withValues(alpha: isDark ? 0.02 : 0),
                  overlay.withValues(alpha: isDark ? 0.28 : 0.08),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
