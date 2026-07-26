import 'package:flutter/material.dart';

import '../../app/theme.dart';

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    required this.title,
    required this.child,
    this.actions,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final pagePadding = width < 600
        ? const EdgeInsets.fromLTRB(
            KairosSpacing.md,
            KairosSpacing.md,
            KairosSpacing.md,
            0,
          )
        : width < 900
            ? const EdgeInsets.fromLTRB(
                KairosSpacing.lg,
                KairosSpacing.lg,
                KairosSpacing.lg,
                0,
              )
            : const EdgeInsets.fromLTRB(
                KairosSpacing.xl,
                KairosSpacing.xl,
                KairosSpacing.xl,
                0,
              );
    final contentBottomPadding =
        width < 720 ? 104.0 + bottomInset : KairosSpacing.xl;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: pagePadding,
          sliver: SliverToBoxAdapter(
            child: _PageFrame(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 320;
                  final titleBlock = _PageTitle(
                    title: title,
                    subtitle: subtitle,
                    theme: theme,
                  );
                  final actionBlock = actions == null
                      ? null
                      : Wrap(
                          spacing: KairosSpacing.sm,
                          runSpacing: KairosSpacing.sm,
                          children: actions!,
                        );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleBlock,
                        if (actionBlock != null) ...[
                          const SizedBox(height: KairosSpacing.md),
                          actionBlock,
                        ],
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: titleBlock),
                      if (actionBlock != null) ...[
                        const SizedBox(width: KairosSpacing.md),
                        actionBlock,
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: pagePadding.copyWith(
            top: KairosSpacing.lg,
            bottom: contentBottomPadding,
          ),
          sliver: SliverToBoxAdapter(
            child: _PageFrame(child: child),
          ),
        ),
      ],
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1220),
        child: child,
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({
    required this.title,
    required this.theme,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.displayLarge),
        if (subtitle != null) ...[
          const SizedBox(height: KairosSpacing.sm),
          Text(
            subtitle!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
