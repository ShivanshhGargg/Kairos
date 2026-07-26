import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/kairos_models.dart';
import '../../../shared/data/kairos_repository.dart';
import '../../../shared/widgets/kairos_card.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_pill.dart';

enum _InboxFilter { all, events, bills, messages }

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  _InboxFilter _filter = _InboxFilter.all;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(kairosRepositoryProvider);
    final visibleItems = _filteredItems(data.needsReview, _filter);

    return PageScaffold(
      title: 'Inbox',
      subtitle: 'Items Kai found that need your review.',
      actions: [
        Tooltip(
          message: 'New message',
          child: IconButton.filledTonal(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.go('/chat'),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilterTabs(
            selected: _filter,
            items: data.needsReview,
            onSelected: (filter) => setState(() => _filter = filter),
          ),
          const SizedBox(height: KairosSpacing.lg),
          SectionHeader(
            title: 'Today',
            subtitle: '${visibleItems.length} pending',
          ),
          const SizedBox(height: KairosSpacing.md),
          if (visibleItems.isEmpty)
            const KairosCard(child: Text('No items in this view.'))
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900 ? 2 : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleItems.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: KairosSpacing.md,
                    mainAxisSpacing: KairosSpacing.md,
                    mainAxisExtent: 292,
                  ),
                  itemBuilder: (context, index) {
                    return _ReviewCard(item: visibleItems[index]);
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.selected,
    required this.items,
    required this.onSelected,
  });

  final _InboxFilter selected;
  final List<NeedsReviewItem> items;
  final ValueChanged<_InboxFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _InboxFilter.values) ...[
            ChoiceChip(
              label: Text('${_filterLabel(filter)} ${_count(items, filter)}'),
              selected: selected == filter,
              onSelected: (_) => onSelected(filter),
            ),
            const SizedBox(width: KairosSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.item});

  final NeedsReviewItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = confidenceColor(item.confidenceLevel);
    final source = _sourceMeta(item);

    return KairosCard(
      borderColor: color.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SourceIcon(source: source),
              const SizedBox(width: KairosSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: KairosSpacing.xs),
                    Text(
                      item.source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: source.label,
                color: source.color,
              ),
            ],
          ),
          const SizedBox(height: KairosSpacing.md),
          for (final entry in item.extractedFields.entries.take(3)) ...[
            _FieldLine(label: entry.key, value: entry.value),
            const SizedBox(height: KairosSpacing.xs),
          ],
          const Spacer(),
          _ConfidenceBar(value: item.confidence, color: color),
          const SizedBox(height: KairosSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showEditReady(context),
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: KairosSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ref
                        .read(kairosRepositoryProvider.notifier)
                        .confirmReview(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Memory created.')),
                    );
                  },
                  child: const Text('Accept'),
                ),
              ),
              const SizedBox(width: KairosSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref
                        .read(kairosRepositoryProvider.notifier)
                        .ignoreReview(item.id);
                  },
                  child: const Text('Ignore'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceIcon extends StatelessWidget {
  const _SourceIcon({required this.source});

  final _SourceMeta source;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: source.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(KairosRadius.md),
      ),
      child: Icon(source.icon, color: source.color),
    );
  }
}

class _FieldLine extends StatelessWidget {
  const _FieldLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: KairosSpacing.sm),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  const _ConfidenceBar({
    required this.value,
    required this.color,
  });

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Confidence',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '${(value * 100).round()}%',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: KairosSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(KairosRadius.sm),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 7,
            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.22),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _SourceMeta {
  const _SourceMeta({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

List<NeedsReviewItem> _filteredItems(
  List<NeedsReviewItem> items,
  _InboxFilter filter,
) {
  return [
    for (final item in items)
      if (filter == _InboxFilter.all || _categoryFor(item) == filter) item,
  ];
}

int _count(List<NeedsReviewItem> items, _InboxFilter filter) {
  if (filter == _InboxFilter.all) return items.length;
  return items.where((item) => _categoryFor(item) == filter).length;
}

String _filterLabel(_InboxFilter filter) {
  return switch (filter) {
    _InboxFilter.all => 'All',
    _InboxFilter.events => 'Events',
    _InboxFilter.bills => 'Bills',
    _InboxFilter.messages => 'Messages',
  };
}

_InboxFilter _categoryFor(NeedsReviewItem item) {
  final joined = [
    item.title,
    item.source,
    ...item.extractedFields.keys,
    ...item.extractedFields.values,
  ].join(' ').toLowerCase();
  if (joined.contains('amount') ||
      joined.contains('invoice') ||
      joined.contains('subscription') ||
      joined.contains('bill')) {
    return _InboxFilter.bills;
  }
  if (joined.contains('date') ||
      joined.contains('meeting') ||
      joined.contains('orientation') ||
      joined.contains('due')) {
    return _InboxFilter.events;
  }
  return _InboxFilter.messages;
}

_SourceMeta _sourceMeta(NeedsReviewItem item) {
  final source = item.source.toLowerCase();
  if (source.contains('email')) {
    return const _SourceMeta(
      label: 'Email',
      icon: Icons.mail_rounded,
      color: Color(0xFFEA4335),
    );
  }
  if (source.contains('screenshot')) {
    return const _SourceMeta(
      label: 'Image',
      icon: Icons.image_rounded,
      color: Color(0xFF60A5FA),
    );
  }
  return const _SourceMeta(
    label: 'Message',
    icon: Icons.chat_rounded,
    color: KairosColors.accent,
  );
}

void _showEditReady(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Edit flow is ready for API wiring.')),
  );
}
