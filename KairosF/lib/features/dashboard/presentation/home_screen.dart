import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/models/kairos_models.dart';
import '../../../shared/data/kairos_repository.dart';
import '../../../shared/widgets/kairos_card.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_pill.dart';

enum _PlanView { list, timeline, flow }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _PlanView _view = _PlanView.flow;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(kairosRepositoryProvider);
    final profile = data.profile;
    final date = DateFormat('EEEE, MMM d').format(DateTime.now());
    final planItems = _planItems(data.dashboard);

    return PageScaffold(
      title: 'Good morning, ${profile.fullName}',
      subtitle: date,
      actions: [
        Tooltip(
          message: 'Notifications',
          child: IconButton.filledTonal(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.go('/notifications'),
          ),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          final main = _TodayMain(
            data: data,
            items: planItems,
            view: _view,
            onViewChanged: (value) => setState(() => _view = value),
          );
          final side = _TodaySide(data: data);

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                main,
                const SizedBox(height: KairosSpacing.lg),
                side,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: main),
              const SizedBox(width: KairosSpacing.lg),
              Expanded(flex: 4, child: side),
            ],
          );
        },
      ),
    );
  }
}

class _TodayMain extends StatelessWidget {
  const _TodayMain({
    required this.data,
    required this.items,
    required this.view,
    required this.onViewChanged,
  });

  final KairosData data;
  final List<_PlanItem> items;
  final _PlanView view;
  final ValueChanged<_PlanView> onViewChanged;

  @override
  Widget build(BuildContext context) {
    final blocked = data.dashboard.risks
        .where((risk) => risk.severity == ConfidenceLevel.high)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricGrid(
          metrics: [
            _Metric(
              label: 'Tasks',
              value: '${items.length}',
              color: Theme.of(context).colorScheme.primary,
            ),
            _Metric(
              label: 'Need Review',
              value: '${data.needsReview.length}',
              color: KairosColors.warning,
            ),
            _Metric(
              label: 'Blocked',
              value: '$blocked',
              color: KairosColors.critical,
            ),
          ],
        ),
        const SizedBox(height: KairosSpacing.xl),
        _ScheduleHeader(
          view: view,
          onViewChanged: onViewChanged,
        ),
        const SizedBox(height: KairosSpacing.md),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          child: switch (view) {
            _PlanView.list => _ListPlan(items: items),
            _PlanView.timeline => _TimelinePlan(items: items),
            _PlanView.flow => _FlowPlan(items: items),
          },
        ),
        const SizedBox(height: KairosSpacing.lg),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.rocket_launch_rounded),
            label: const Text('Start My Day'),
            onPressed: () => context.go('/chat'),
          ),
        ),
      ],
    );
  }
}

class _TodaySide extends ConsumerWidget {
  const _TodaySide({required this.data});

  final KairosData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Needs Review',
          subtitle: '${data.needsReview.length} pending',
          trailing: TextButton(
            onPressed: () => context.go('/inbox'),
            child: const Text('Open'),
          ),
        ),
        const SizedBox(height: KairosSpacing.md),
        if (data.needsReview.isEmpty)
          const KairosCard(child: Text('No new items.'))
        else
          for (final item in data.needsReview.take(2)) ...[
            _ReviewPreviewCard(item: item),
            const SizedBox(height: KairosSpacing.sm),
          ],
        const SizedBox(height: KairosSpacing.lg),
        const SectionHeader(title: 'Blocked'),
        const SizedBox(height: KairosSpacing.md),
        for (final risk in data.dashboard.risks.take(2)) ...[
          _RiskPreviewCard(risk: risk),
          const SizedBox(height: KairosSpacing.sm),
        ],
        const SizedBox(height: KairosSpacing.lg),
        const SectionHeader(title: 'Briefing Notes'),
        const SizedBox(height: KairosSpacing.md),
        KairosCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final insight in data.dashboard.insights) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: KairosSpacing.sm),
                    Expanded(child: Text(insight)),
                  ],
                ),
                const SizedBox(height: KairosSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({
    required this.view,
    required this.onViewChanged,
  });

  final _PlanView view;
  final ValueChanged<_PlanView> onViewChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final switcher = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _ViewSwitcher(value: view, onChanged: onViewChanged),
        );
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Today\'s Schedule'),
              const SizedBox(height: KairosSpacing.sm),
              switcher,
            ],
          );
        }

        return SectionHeader(
          title: 'Today\'s Schedule',
          trailing: switcher,
        );
      },
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 520 ? 2 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: KairosSpacing.sm,
            mainAxisSpacing: KairosSpacing.sm,
            mainAxisExtent: 92,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return KairosCard(
              padding: const EdgeInsets.all(KairosSpacing.md),
              borderColor: metric.color.withValues(alpha: 0.3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    metric.value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: metric.color,
                        ),
                  ),
                  const SizedBox(height: KairosSpacing.xs),
                  Text(
                    metric.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ViewSwitcher extends StatelessWidget {
  const _ViewSwitcher({
    required this.value,
    required this.onChanged,
  });

  final _PlanView value;
  final ValueChanged<_PlanView> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_PlanView>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: _PlanView.list,
          icon: Icon(Icons.format_list_bulleted_rounded),
          label: Text('List'),
        ),
        ButtonSegment(
          value: _PlanView.timeline,
          icon: Icon(Icons.timeline_rounded),
          label: Text('Timeline'),
        ),
        ButtonSegment(
          value: _PlanView.flow,
          icon: Icon(Icons.account_tree_rounded),
          label: Text('Flow'),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _ListPlan extends StatelessWidget {
  const _ListPlan({required this.items});

  final List<_PlanItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyPlanCard(key: ValueKey('list-plan'));

    return Column(
      key: const ValueKey('list-plan'),
      children: [
        for (final item in items) ...[
          _PlanRow(item: item),
          const SizedBox(height: KairosSpacing.sm),
        ],
      ],
    );
  }
}

class _TimelinePlan extends StatelessWidget {
  const _TimelinePlan({required this.items});

  final List<_PlanItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyPlanCard(key: ValueKey('timeline-plan'));
    }

    return Column(
      key: const ValueKey('timeline-plan'),
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _TimelineRow(item: items[i], isLast: i == items.length - 1),
        ],
      ],
    );
  }
}

class _FlowPlan extends StatelessWidget {
  const _FlowPlan({required this.items});

  final List<_PlanItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyPlanCard(key: ValueKey('flow-plan'));

    return Column(
      key: const ValueKey('flow-plan'),
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _FlowNode(item: items[i]),
          if (i != items.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: KairosSpacing.xs),
              child: Icon(
                Icons.arrow_downward_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 18,
              ),
            ),
        ],
      ],
    );
  }
}

class _EmptyPlanCard extends StatelessWidget {
  const _EmptyPlanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return KairosCard(
      child: Row(
        children: [
          Icon(
            Icons.event_available_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: KairosSpacing.md),
          Expanded(
            child: Text(
              'No plan items yet.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.item});

  final _PlanItem item;

  @override
  Widget build(BuildContext context) {
    return KairosCard(
      onTap: item.workflowId == null
          ? null
          : () => context.go('/workflow/${item.workflowId}'),
      child: Row(
        children: [
          _PlanIcon(item: item),
          const SizedBox(width: KairosSpacing.md),
          Expanded(child: _PlanText(item: item)),
          _StatusRing(item: item),
          const SizedBox(width: KairosSpacing.sm),
          Icon(
            Icons.drag_indicator_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.item,
    required this.isLast,
  });

  final _PlanItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 74,
          child: Text(
            item.timeLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 70,
                color: theme.colorScheme.outline.withValues(alpha: 0.45),
              ),
          ],
        ),
        const SizedBox(width: KairosSpacing.md),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : KairosSpacing.sm),
            child: _PlanRow(item: item),
          ),
        ),
      ],
    );
  }
}

class _FlowNode extends StatelessWidget {
  const _FlowNode({required this.item});

  final _PlanItem item;

  @override
  Widget build(BuildContext context) {
    return KairosCard(
      onTap: item.workflowId == null
          ? null
          : () => context.go('/workflow/${item.workflowId}'),
      child: Row(
        children: [
          _PlanIcon(item: item),
          const SizedBox(width: KairosSpacing.md),
          Expanded(child: _PlanText(item: item)),
          _StatusRing(item: item),
        ],
      ),
    );
  }
}

class _PlanIcon extends StatelessWidget {
  const _PlanIcon({required this.item});

  final _PlanItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(KairosRadius.md),
      ),
      child: Icon(item.icon, color: item.color),
    );
  }
}

class _PlanText extends StatelessWidget {
  const _PlanText({required this.item});

  final _PlanItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
          item.timeLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatusRing extends StatelessWidget {
  const _StatusRing({required this.item});

  final _PlanItem item;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.radio_button_unchecked_rounded,
      color: item.blocked ? KairosColors.critical : item.color,
    );
  }
}

class _ReviewPreviewCard extends ConsumerWidget {
  const _ReviewPreviewCard({required this.item});

  final NeedsReviewItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = confidenceColor(item.confidenceLevel);
    return KairosCard(
      borderColor: color.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined, color: color),
              const SizedBox(width: KairosSpacing.sm),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: KairosSpacing.sm),
          StatusPill(
            label: '${(item.confidence * 100).round()}%',
            color: color,
            icon: Icons.psychology_alt_rounded,
          ),
          const SizedBox(height: KairosSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/inbox'),
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
                  },
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskPreviewCard extends StatelessWidget {
  const _RiskPreviewCard({required this.risk});

  final RiskItem risk;

  @override
  Widget build(BuildContext context) {
    final color = confidenceColor(risk.severity);
    return KairosCard(
      borderColor: color.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(
                label: risk.severity.label,
                icon: Icons.warning_amber_rounded,
                color: color,
              ),
              const Spacer(),
              Text(
                risk.dueLabel,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: KairosSpacing.sm),
          Text(risk.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: KairosSpacing.xs),
          Text(
            risk.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _Metric {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;
}

class _PlanItem {
  const _PlanItem({
    required this.title,
    required this.timeLabel,
    required this.icon,
    required this.color,
    this.workflowId,
    this.blocked = false,
  });

  final String title;
  final String timeLabel;
  final IconData icon;
  final Color color;
  final String? workflowId;
  final bool blocked;
}

List<_PlanItem> _planItems(DashboardData dashboard) {
  final priorityItems = [
    if (dashboard.nextMove != null) dashboard.nextMove!,
    ...dashboard.everythingElse,
  ];

  return [
    for (final item in priorityItems.take(5))
      _PlanItem(
        title: item.title,
        timeLabel: item.dueLabel,
        icon: _iconForType(item.type),
        color: _colorForType(item.type),
        workflowId: item.workflowId,
        blocked: item.type == MemoryType.subscription,
      ),
  ];
}

IconData _iconForType(MemoryType type) {
  return switch (type) {
    MemoryType.bill => Icons.receipt_long_rounded,
    MemoryType.exam => Icons.school_rounded,
    MemoryType.assignment => Icons.assignment_rounded,
    MemoryType.meeting => Icons.groups_rounded,
    MemoryType.subscription => Icons.autorenew_rounded,
    MemoryType.travel => Icons.flight_takeoff_rounded,
    MemoryType.goal => Icons.flag_rounded,
    MemoryType.note => Icons.notes_rounded,
  };
}

Color _colorForType(MemoryType type) {
  return switch (type) {
    MemoryType.bill => KairosColors.warning,
    MemoryType.exam => const Color(0xFF38BDF8),
    MemoryType.assignment => KairosColors.primaryDark,
    MemoryType.meeting => KairosColors.accent,
    MemoryType.subscription => KairosColors.critical,
    MemoryType.travel => const Color(0xFF60A5FA),
    MemoryType.goal => KairosColors.success,
    MemoryType.note => const Color(0xFF94A3B8),
  };
}
