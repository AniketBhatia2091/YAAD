import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/color_tokens.dart';
import '../../app/theme/radius_tokens.dart';
import '../../app/theme/shadow_tokens.dart';
import '../../app/theme/spacing_tokens.dart';
import '../../app/theme/typography_tokens.dart';
import '../../data/models/vault_category.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(vaultCategoriesProvider);

    return Scaffold(
      backgroundColor: YaadColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: YaadSpacing.md, vertical: YaadSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vault Header
              Text(
                'Life Vault',
                style: YaadTypography.displayLarge.copyWith(letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Organized by your real life, not file folders.',
                style: YaadTypography.bodyMedium.copyWith(
                  color: YaadColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: YaadSpacing.lg),

              // Categories Grid
              Expanded(
                child: categoriesAsync.when(
                  data: (categories) => _buildCategoryList(context, categories),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const Center(child: Text('Failed to load categories')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, List<VaultCategory> categories) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: YaadSpacing.sm),
          child: Container(
            padding: YaadSpacing.cardPadding,
            decoration: BoxDecoration(
              color: YaadColors.surfaceLight,
              borderRadius: YaadRadius.borderLg,
              border: Border.all(color: YaadColors.borderLight),
              boxShadow: YaadShadows.subtle,
            ),
            child: Row(
              children: [
                // Category Colored Icon Container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cat.backgroundColor,
                    borderRadius: YaadRadius.borderMd,
                  ),
                  child: Icon(
                    cat.icon,
                    size: 26,
                    color: cat.iconColor,
                  ),
                ),
                const SizedBox(width: 16),

                // Category Title & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.title,
                        style: YaadTypography.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cat.description,
                        style: YaadTypography.bodyMedium.copyWith(
                          fontSize: 13,
                          color: YaadColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),

                // Memory Count Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: YaadColors.surfaceSubtleLight,
                    borderRadius: YaadRadius.borderPill,
                    border: Border.all(color: YaadColors.borderLight),
                  ),
                  child: Text(
                    '${cat.count}',
                    style: YaadTypography.labelSmall.copyWith(
                      color: YaadColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
