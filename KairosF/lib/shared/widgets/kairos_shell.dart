import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../features/auth/application/auth_controller.dart';
import '../data/kairos_repository.dart';
import 'kairos_background.dart';

class KairosShell extends ConsumerWidget {
  const KairosShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 760) {
      return _MobileShell(child: child);
    }
    return _RailShell(child: child);
  }
}

class _RailShell extends ConsumerWidget {
  const _RailShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _selectedIndex(context);
    final repository = ref.watch(kairosRepositoryProvider);
    final reviewCount = repository.needsReview.length;

    return KairosBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(KairosSpacing.md),
                child: _GlassNavFrame(
                  child: SizedBox(
                    width: 92,
                    child: NavigationRail(
                      backgroundColor: Colors.transparent,
                      minWidth: 92,
                      groupAlignment: -0.68,
                      selectedIndex: selectedIndex,
                      labelType: NavigationRailLabelType.all,
                      onDestinationSelected: (index) =>
                          _goToIndex(context, index),
                      leading: const Padding(
                        padding: EdgeInsets.only(
                          top: KairosSpacing.sm,
                          bottom: KairosSpacing.lg,
                        ),
                        child: Center(child: _BrandMark(size: 48)),
                      ),
                      trailing: Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: KairosSpacing.sm,
                            ),
                            child: Tooltip(
                              message: 'Sign out',
                              child: IconButton.filledTonal(
                                icon: const Icon(Icons.logout_rounded),
                                onPressed: () {
                                  ref
                                      .read(authControllerProvider.notifier)
                                      .signOut();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      destinations: _railDestinations(reviewCount),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _MobileShell extends ConsumerWidget {
  const _MobileShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _selectedIndex(context);
    final reviewCount = ref.watch(kairosRepositoryProvider).needsReview.length;

    return KairosBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: child,
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            KairosSpacing.md,
            0,
            KairosSpacing.md,
            KairosSpacing.sm,
          ),
          child: _GlassNavFrame(
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _goToIndex(context, index),
              destinations: _barDestinations(reviewCount),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavFrame extends StatelessWidget {
  const _GlassNavFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(KairosRadius.md);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: theme.colorScheme.surface.withValues(
              alpha: isDark ? 0.2 : 0.56,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.76),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                blurRadius: 28,
                spreadRadius: -12,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/kairos-mark.png',
      width: size,
      height: size,
    );
  }
}

List<NavigationRailDestination> _railDestinations(int reviewCount) {
  return [
    const NavigationRailDestination(
      icon: Icon(Icons.chat_bubble_outline_rounded),
      selectedIcon: Icon(Icons.chat_bubble_rounded),
      label: Text('Chat'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.wb_sunny_outlined),
      selectedIcon: Icon(Icons.wb_sunny_rounded),
      label: Text('Today'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.grid_view_outlined),
      selectedIcon: Icon(Icons.grid_view_rounded),
      label: Text('Apps'),
    ),
    NavigationRailDestination(
      icon: Badge(
        isLabelVisible: reviewCount > 0,
        label: Text('$reviewCount'),
        child: const Icon(Icons.move_to_inbox_outlined),
      ),
      selectedIcon: Badge(
        isLabelVisible: reviewCount > 0,
        label: Text('$reviewCount'),
        child: const Icon(Icons.move_to_inbox_rounded),
      ),
      label: const Text('Inbox'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: Text('You'),
    ),
  ];
}

List<NavigationDestination> _barDestinations(int reviewCount) {
  return [
    const NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline_rounded),
      selectedIcon: Icon(Icons.chat_bubble_rounded),
      label: 'Chat',
    ),
    const NavigationDestination(
      icon: Icon(Icons.wb_sunny_outlined),
      selectedIcon: Icon(Icons.wb_sunny_rounded),
      label: 'Today',
    ),
    const NavigationDestination(
      icon: Icon(Icons.grid_view_outlined),
      selectedIcon: Icon(Icons.grid_view_rounded),
      label: 'Apps',
    ),
    NavigationDestination(
      icon: Badge(
        isLabelVisible: reviewCount > 0,
        label: Text('$reviewCount'),
        child: const Icon(Icons.move_to_inbox_outlined),
      ),
      selectedIcon: Badge(
        isLabelVisible: reviewCount > 0,
        label: Text('$reviewCount'),
        child: const Icon(Icons.move_to_inbox_rounded),
      ),
      label: 'Inbox',
    ),
    const NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'You',
    ),
  ];
}

int _selectedIndex(BuildContext context) {
  final path = GoRouterState.of(context).uri.path;
  if (path.startsWith('/chat')) return 0;
  if (path.startsWith('/today') ||
      path.startsWith('/home') ||
      path.startsWith('/workflow')) {
    return 1;
  }
  if (path.startsWith('/apps') ||
      path.startsWith('/memories') ||
      path.startsWith('/memory')) {
    return 2;
  }
  if (path.startsWith('/inbox') || path.startsWith('/notifications')) return 3;
  if (path.startsWith('/profile') || path.startsWith('/settings')) return 4;
  return 1;
}

void _goToIndex(BuildContext context, int index) {
  final destinations = [
    '/chat',
    '/today',
    '/apps',
    '/inbox',
    '/profile',
  ];
  context.go(destinations[index]);
}
