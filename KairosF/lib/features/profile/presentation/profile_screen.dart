import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../features/auth/application/auth_controller.dart';
import '../../../shared/data/kairos_repository.dart';
import '../../../shared/widgets/kairos_card.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/section_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageScaffold(
      title: 'You',
      subtitle: 'Your account, memory, preferences.',
      actions: [
        Tooltip(
          message: 'Sign out',
          child: IconButton.filledTonal(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;

          if (!wide) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _IdentityColumn(),
                SizedBox(height: KairosSpacing.lg),
                _SettingsColumn(),
              ],
            );
          }

          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: _IdentityColumn()),
              SizedBox(width: KairosSpacing.lg),
              Expanded(flex: 6, child: _SettingsColumn()),
            ],
          );
        },
      ),
    );
  }
}

class _IdentityColumn extends ConsumerWidget {
  const _IdentityColumn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(kairosRepositoryProvider).profile;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KairosCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      profile.fullName.characters.first.toUpperCase(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: KairosSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                profile.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: KairosSpacing.xs),
                        Text(
                          profile.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: KairosSpacing.xs),
                        Text(
                          profile.occupation.isEmpty
                              ? 'Kairos account'
                              : profile.occupation,
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KairosSpacing.lg),
              _InfoLine(label: 'Inbox', value: profile.kairosInboxAddress),
              _InfoLine(label: 'Timezone', value: profile.timezone),
              _InfoLine(label: 'Currency', value: profile.currency),
            ],
          ),
        ),
        const SizedBox(height: KairosSpacing.lg),
        const SectionHeader(title: 'Security'),
        const SizedBox(height: KairosSpacing.md),
        const KairosCard(
          child: Column(
            children: [
              _SettingsRow(
                icon: Icons.key_rounded,
                title: 'Passkeys',
                subtitle: 'Manage sign-in',
              ),
              Divider(height: KairosSpacing.lg),
              _SettingsRow(
                icon: Icons.devices_rounded,
                title: 'Connected Devices',
                subtitle: 'Manage sessions',
              ),
              Divider(height: KairosSpacing.lg),
              _SettingsRow(
                icon: Icons.policy_rounded,
                title: 'Audit Logs',
                subtitle: 'Review activity',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsColumn extends ConsumerWidget {
  const _SettingsColumn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(kairosRepositoryProvider).profile;
    final themeMode = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Notifications'),
        const SizedBox(height: KairosSpacing.md),
        KairosCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'How often should Kai notify you?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    child: Text(
                      '${(profile.notificationIntensity * 100).round()}%',
                    ),
                  ),
                ],
              ),
              Slider(
                value: profile.notificationIntensity,
                onChanged: (value) {
                  ref.read(kairosRepositoryProvider.notifier).updateProfile(
                        notificationIntensity: value,
                      );
                },
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quiet'),
                  Text('Balanced'),
                  Text('Active'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: KairosSpacing.lg),
        const SectionHeader(title: 'Preferences'),
        const SizedBox(height: KairosSpacing.md),
        KairosCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Theme', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: KairosSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.devices_rounded),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selection) {
                    ref.read(themeModeProvider.notifier).state =
                        selection.first;
                  },
                ),
              ),
              const Divider(height: KairosSpacing.xl),
              _BriefingTimePicker(current: profile.dailyBriefingTime),
              const Divider(height: KairosSpacing.xl),
              _PreferenceSwitchRow(
                icon: Icons.notifications_active_outlined,
                title: 'Push notifications',
                value: profile.pushEnabled,
                onChanged: (value) {
                  ref.read(kairosRepositoryProvider.notifier).updateProfile(
                        pushEnabled: value,
                      );
                },
              ),
              const Divider(height: KairosSpacing.lg),
              _PreferenceSwitchRow(
                icon: Icons.mark_email_read_outlined,
                title: 'Email summaries',
                value: profile.emailEnabled,
                onChanged: (value) {
                  ref.read(kairosRepositoryProvider.notifier).updateProfile(
                        emailEnabled: value,
                      );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: KairosSpacing.lg),
        KairosCard(
          borderColor: KairosColors.critical.withValues(alpha: 0.34),
          onTap: () => _confirmDelete(context),
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: KairosColors.critical,
              ),
              const SizedBox(width: KairosSpacing.md),
              Expanded(
                child: Text(
                  'Delete All Data & Disconnect Apps',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: KairosColors.critical,
                      ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: KairosColors.critical,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content:
              const Text('This will disconnect apps and request deletion.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}

class _PreferenceSwitchRow extends StatelessWidget {
  const _PreferenceSwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: KairosSpacing.md),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _BriefingTimePicker extends ConsumerWidget {
  const _BriefingTimePicker({required this.current});

  final String current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily briefing',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: KairosSpacing.sm),
        Wrap(
          spacing: KairosSpacing.sm,
          runSpacing: KairosSpacing.sm,
          children: [
            for (final time in const ['07:00', '08:00', '09:00'])
              ChoiceChip(
                label: Text(time),
                selected: current == time,
                onSelected: (_) {
                  ref.read(kairosRepositoryProvider.notifier).updateProfile(
                        dailyBriefingTime: time,
                      );
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: KairosSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: KairosSpacing.xs),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: KairosSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
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
      ),
    );
  }
}
