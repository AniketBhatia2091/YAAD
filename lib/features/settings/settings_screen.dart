import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/color_tokens.dart';
import '../../app/theme/radius_tokens.dart';
import '../../app/theme/spacing_tokens.dart';
import '../../app/theme/typography_tokens.dart';
import '../../core/constants/app_constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? YaadColors.surfaceDark : YaadColors.surfaceLight;
    final borderColor = isDark ? YaadColors.borderDark : YaadColors.borderLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: YaadSpacing.pagePadding,
          children: [
            // User Profile Card
            Container(
              padding: YaadSpacing.cardPadding,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: YaadRadius.borderLg,
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: YaadColors.goldPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'YA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aniket Bhatia',
                          style: YaadTypography.titleMediumOf(context),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Personal Memory Vault',
                          style: YaadTypography.bodyMediumOf(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: YaadSpacing.lg),

            // Settings Items Group
            _buildSettingsSection(
              context,
              'PREFERENCES & SECURITY',
              [
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Appearance',
                  subtitle: _getThemeModeLabel(ref.watch(themeModeProvider)),
                  onTap: () => _showThemeModeDialog(context, ref),
                ),
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                  subtitle: 'Manage profile and personal details',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile section shell ready')),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Privacy & Security',
                  subtitle: 'On-device sandbox isolation & local storage',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All document memories remain strictly on your local device.')),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Bill reminders and expiry alerts',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications section ready')),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'English (India)',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Language selection ready')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: YaadSpacing.md),

            _buildSettingsSection(
              context,
              'VAULT & SYNC',
              [
                _SettingsTile(
                  icon: Icons.people_outline_rounded,
                  title: 'Family Vault',
                  subtitle: 'Share memories with family locally',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Family Vault section ready')),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.save_alt_rounded,
                  title: 'Backup & Export',
                  subtitle: 'Local device export & backup',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Backup and export options ready')),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.star_outline_rounded,
                  title: 'Subscription',
                  subtitle: 'YAAD Free Plan',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('YAAD Free Plan is active')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: YaadSpacing.md),

            _buildSettingsSection(
              context,
              'ABOUT',
              [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About YAAD',
                  subtitle: '${AppConstants.appName} v1.0.0 — ${AppConstants.tagline}',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('${AppConstants.appName} v1.0.0')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: YaadSpacing.lg),

            // Dev / Testing Helper: Reset Onboarding
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(onboardingCompletedProvider.notifier).resetOnboarding();
                if (context.mounted) {
                  context.go('/onboarding');
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Replay Onboarding (Dev Tool)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: YaadColors.attentionUrgent,
                side: const BorderSide(color: YaadColors.attentionUrgentBg),
              ),
            ),
            const SizedBox(height: YaadSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String sectionTitle,
    List<_SettingsTile> tiles,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            sectionTitle,
            style: YaadTypography.labelSmall.copyWith(
              color: YaadColors.textMutedLight,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final cardBg = isDark ? YaadColors.surfaceDark : YaadColors.surfaceLight;
            final borderColor = isDark ? YaadColors.borderDark : YaadColors.borderLight;
            final iconColor = isDark ? YaadColors.goldAccent : YaadColors.primary;
            final dividerColor = isDark ? YaadColors.borderDark : YaadColors.borderLight;

            return Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: YaadRadius.borderLg,
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: tiles.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final tile = entry.value;
                  final isLast = idx == tiles.length - 1;
                  return Column(
                    children: [
                      ListTile(
                        leading: Icon(tile.icon, color: iconColor),
                        title: Text(tile.title, style: YaadTypography.titleSmallOf(context)),
                        subtitle: Text(
                          tile.subtitle,
                          style: YaadTypography.bodyMediumOf(context).copyWith(fontSize: 13),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: YaadColors.textMutedLight),
                        onTap: tile.onTap,
                      ),
                      if (!isLast) Divider(height: 1, color: dividerColor),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark (Default)';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref) {
    final current = ref.read(themeModeProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Theme',
                  style: YaadTypography.titleLargeOf(context),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.dark_mode_rounded, color: YaadColors.goldAccent),
                  title: const Text('Dark (Recommended)'),
                  subtitle: const Text('Premium obsidian & gold experience'),
                  trailing: current == ThemeMode.dark ? const Icon(Icons.check_rounded, color: YaadColors.goldAccent) : null,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.light_mode_rounded, color: YaadColors.goldAccent),
                  title: const Text('Light'),
                  subtitle: const Text('Calm clean sand palette'),
                  trailing: current == ThemeMode.light ? const Icon(Icons.check_rounded, color: YaadColors.goldAccent) : null,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_system_daydream_rounded, color: YaadColors.goldAccent),
                  title: const Text('System'),
                  subtitle: const Text('Match device appearance setting'),
                  trailing: current == ThemeMode.system ? const Icon(Icons.check_rounded, color: YaadColors.goldAccent) : null,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingsTile {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
}
