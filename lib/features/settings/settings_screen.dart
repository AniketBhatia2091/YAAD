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
    return Scaffold(
      backgroundColor: YaadColors.backgroundLight,
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
                color: YaadColors.surfaceLight,
                borderRadius: YaadRadius.borderLg,
                border: Border.all(color: YaadColors.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: YaadColors.primary,
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
                        const Text(
                          'Aniket Bhatia',
                          style: YaadTypography.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Personal Memory Vault',
                          style: YaadTypography.bodyMedium.copyWith(
                            color: YaadColors.textSecondaryLight,
                          ),
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
              const [
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                  subtitle: 'Manage profile and personal details',
                ),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Privacy & Security',
                  subtitle: 'On-device encryption & credentials',
                ),
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Bill reminders and expiry alerts',
                ),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'English (India)',
                ),
              ],
            ),
            const SizedBox(height: YaadSpacing.md),

            _buildSettingsSection(
              context,
              'VAULT & SYNC',
              const [
                _SettingsTile(
                  icon: Icons.people_outline_rounded,
                  title: 'Family Vault',
                  subtitle: 'Securely share memories with family',
                ),
                _SettingsTile(
                  icon: Icons.cloud_outlined,
                  title: 'Backup & Export',
                  subtitle: 'Encrypted local and cloud backups',
                ),
                _SettingsTile(
                  icon: Icons.star_outline_rounded,
                  title: 'Subscription',
                  subtitle: 'YAAD Free Plan',
                ),
              ],
            ),
            const SizedBox(height: YaadSpacing.md),

            _buildSettingsSection(
              context,
              'ABOUT',
              const [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About YAAD',
                  subtitle: '${AppConstants.appName} v0.1.0 — ${AppConstants.tagline}',
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
        Container(
          decoration: BoxDecoration(
            color: YaadColors.surfaceLight,
            borderRadius: YaadRadius.borderLg,
            border: Border.all(color: YaadColors.borderLight),
          ),
          child: Column(
            children: tiles.asMap().entries.map((entry) {
              final idx = entry.key;
              final tile = entry.value;
              final isLast = idx == tiles.length - 1;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(tile.icon, color: YaadColors.primary),
                    title: Text(tile.title, style: YaadTypography.titleSmall),
                    subtitle: Text(
                      tile.subtitle,
                      style: YaadTypography.bodyMedium.copyWith(
                        fontSize: 13,
                        color: YaadColors.textSecondaryLight,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: YaadColors.textMutedLight),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${tile.title} section shell ready')),
                      );
                    },
                  ),
                  if (!isLast) const Divider(height: 1, color: YaadColors.borderLight),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
