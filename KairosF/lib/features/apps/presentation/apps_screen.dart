import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/kairos_card.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class AppsScreen extends StatelessWidget {
  const AppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Connected Apps',
      subtitle: 'Manage your connected accounts.',
      actions: [
        Tooltip(
          message: 'Notifications',
          child: IconButton.filledTonal(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.go('/notifications'),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Active Connections',
            trailing: TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ),
          const SizedBox(height: KairosSpacing.md),
          _AppGrid(
            itemCount: _activeApps.length,
            minTileWidth: 160,
            mainAxisExtent: 142,
            builder: (context, index) => _ConnectedAppTile(
              app: _activeApps[index],
            ),
          ),
          const SizedBox(height: KairosSpacing.xl),
          const SectionHeader(title: 'Suggested for You'),
          const SizedBox(height: KairosSpacing.md),
          _AppGrid(
            itemCount: _suggestedApps.length,
            minTileWidth: 180,
            mainAxisExtent: 196,
            builder: (context, index) => _SuggestedAppTile(
              app: _suggestedApps[index],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppGrid extends StatelessWidget {
  const _AppGrid({
    required this.itemCount,
    required this.builder,
    required this.minTileWidth,
    required this.mainAxisExtent,
  });

  final int itemCount;
  final IndexedWidgetBuilder builder;
  final double minTileWidth;
  final double mainAxisExtent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            (constraints.maxWidth / minTileWidth).floor().clamp(1, 6).toInt();
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: KairosSpacing.md,
            mainAxisSpacing: KairosSpacing.md,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: builder,
        );
      },
    );
  }
}

class _ConnectedAppTile extends StatelessWidget {
  const _ConnectedAppTile({required this.app});

  final _KairosAppConnection app;

  @override
  Widget build(BuildContext context) {
    return KairosCard(
      onTap: () => _showConnection(context, app),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AppIconBadge(app: app),
          const Spacer(),
          Text(
            app.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: KairosSpacing.xs),
          _ConnectionStatus(connected: app.connected),
        ],
      ),
    );
  }
}

class _SuggestedAppTile extends StatelessWidget {
  const _SuggestedAppTile({required this.app});

  final _KairosAppConnection app;

  @override
  Widget build(BuildContext context) {
    return KairosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AppIconBadge(app: app, compact: true),
              const Spacer(),
              Tooltip(
                message: 'Dismiss',
                child: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: KairosSpacing.sm),
          Text(
            app.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: KairosSpacing.xs),
          SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                app.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showConnection(context, app),
              child: const Text('Connect'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppIconBadge extends StatelessWidget {
  const _AppIconBadge({
    required this.app,
    this.compact = false,
  });

  final _KairosAppConnection app;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 40.0 : 52.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: app.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(KairosRadius.md),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Icon(app.icon, color: app.color, size: compact ? 22 : 30),
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  const _ConnectionStatus({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final color = connected ? KairosColors.success : KairosColors.textSecondary;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: KairosSpacing.xs),
        Text(
          connected ? 'Connected' : 'Not Connected',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _KairosAppConnection {
  const _KairosAppConnection({
    required this.name,
    required this.icon,
    required this.color,
    required this.detail,
    this.connected = false,
  });

  final String name;
  final IconData icon;
  final Color color;
  final String detail;
  final bool connected;
}

void _showConnection(BuildContext context, _KairosAppConnection app) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('${app.name} settings are ready for API wiring.')),
  );
}

const _activeApps = [
  _KairosAppConnection(
    name: 'Gmail',
    icon: Icons.mail_rounded,
    color: Color(0xFFEA4335),
    detail: 'Email actions',
    connected: true,
  ),
  _KairosAppConnection(
    name: 'Google Calendar',
    icon: Icons.calendar_month_rounded,
    color: Color(0xFF4285F4),
    detail: 'Schedule sync',
    connected: true,
  ),
  _KairosAppConnection(
    name: 'WhatsApp',
    icon: Icons.chat_rounded,
    color: Color(0xFF25D366),
    detail: 'Message intake',
    connected: true,
  ),
  _KairosAppConnection(
    name: 'Notion',
    icon: Icons.article_rounded,
    color: Color(0xFFEDEDED),
    detail: 'Notes and docs',
    connected: true,
  ),
  _KairosAppConnection(
    name: 'Slack',
    icon: Icons.forum_rounded,
    color: Color(0xFF36C5F0),
    detail: 'Workspace updates',
    connected: true,
  ),
  _KairosAppConnection(
    name: 'Drive',
    icon: Icons.folder_rounded,
    color: Color(0xFF34A853),
    detail: 'Files and uploads',
    connected: true,
  ),
];

const _suggestedApps = [
  _KairosAppConnection(
    name: 'Google Docs',
    icon: Icons.description_rounded,
    color: Color(0xFF4285F4),
    detail: 'Create documents after source review.',
  ),
  _KairosAppConnection(
    name: 'Telegram',
    icon: Icons.send_rounded,
    color: Color(0xFF2AABEE),
    detail: 'Import chats and reminders.',
  ),
  _KairosAppConnection(
    name: 'Stripe',
    icon: Icons.payments_rounded,
    color: Color(0xFF635BFF),
    detail: 'Track invoices and payments.',
  ),
];
