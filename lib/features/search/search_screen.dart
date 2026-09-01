import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/color_tokens.dart';
import '../../app/theme/radius_tokens.dart';
import '../../app/theme/shadow_tokens.dart';
import '../../app/theme/spacing_tokens.dart';
import '../../app/theme/typography_tokens.dart';

/// Architecture Note:
/// Search currently performs in-memory and SQLite LIKE matching across title,
/// documentType, category, owner, notes, and structured fields.
/// Full-Text Search (FTS5 / sqlite_fts) is planned for a future release.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _suggestedQueries = const [
    'Untitled memory',
    'Bike insurance',
    'Electricity bills',
    'Warranties',
    'Certificates',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQuerySelected(String query) {
    _searchController.text = query;
    ref.read(searchQueryProvider.notifier).state = query;
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final currentQuery = ref.watch(searchQueryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: YaadSpacing.md, vertical: YaadSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Headline
              Text(
                'Find anything you\'ve remembered.',
                style: (isDark ? YaadTypography.displayLargeDark : YaadTypography.displayLarge).copyWith(
                  letterSpacing: -0.5,
                  color: isDark ? YaadColors.creamText : YaadColors.primary,
                ),
              ),
              const SizedBox(height: YaadSpacing.md),

              // Search Field ("Search your life...")
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).state = val;
                },
                decoration: InputDecoration(
                  hintText: 'Search your life...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? YaadColors.goldAccent : YaadColors.textSecondaryLight,
                  ),
                  suffixIcon: currentQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: isDark ? YaadColors.textMutedDark : YaadColors.textMutedLight,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: YaadSpacing.md),

              // Suggested Query Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _suggestedQueries.map((query) {
                    final isSelected = currentQuery.toLowerCase() == query.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(query),
                        selected: isSelected,
                        onSelected: (_) => _onQuerySelected(query),
                        selectedColor: isDark ? YaadColors.goldPrimary : YaadColors.primary,
                        backgroundColor: isDark ? YaadColors.surfaceDark : YaadColors.surfaceLight,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? YaadColors.creamMuted : YaadColors.textPrimaryLight),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: YaadRadius.borderPill,
                          side: BorderSide(
                            color: isSelected
                                ? (isDark ? YaadColors.goldAccent : YaadColors.primary)
                                : (isDark ? YaadColors.borderDark : YaadColors.borderLight),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: YaadSpacing.lg),

              // Search Results
              Expanded(
                child: searchResultsAsync.when(
                  data: (memories) {
                    if (memories.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: isDark ? YaadColors.textMutedDark : YaadColors.textMutedLight,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No memories matched "$currentQuery"',
                              style: TextStyle(
                                color: isDark ? YaadColors.textSecondaryDark : YaadColors.textSecondaryLight,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: memories.length,
                      itemBuilder: (context, index) {
                        final memory = memories[index];
                        final cardBg = isDark ? YaadColors.surfaceDark : YaadColors.surfaceLight;
                        final borderColor = isDark ? YaadColors.borderDark : YaadColors.borderLight;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: YaadSpacing.sm),
                          child: Semantics(
                            label: 'Result: ${memory.displayTitle}. ${memory.subtitle ?? memory.documentType}',
                            button: true,
                            child: InkWell(
                              onTap: () => context.push('/memory/${memory.id}'),
                              borderRadius: YaadRadius.borderLg,
                              child: Container(
                                padding: YaadSpacing.cardPadding,
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: YaadRadius.borderLg,
                                  border: Border.all(color: borderColor),
                                  boxShadow: YaadShadows.subtle,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDark ? YaadColors.surfaceRaised : YaadColors.surfaceSubtleLight,
                                        borderRadius: YaadRadius.borderMd,
                                      ),
                                      child: Icon(
                                        memory.imagePath != null ? Icons.image_outlined : Icons.description_outlined,
                                        color: isDark ? YaadColors.goldAccent : YaadColors.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            memory.displayTitle,
                                            style: YaadTypography.titleSmallOf(context),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            memory.subtitle ?? memory.documentType,
                                            style: TextStyle(
                                              color: isDark ? YaadColors.textSecondaryDark : YaadColors.textSecondaryLight,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? YaadColors.surfaceRaised : YaadColors.surfaceSubtleLight,
                                        borderRadius: YaadRadius.borderPill,
                                      ),
                                      child: Text(
                                        memory.owner,
                                        style: TextStyle(
                                          color: isDark ? YaadColors.creamMuted : YaadColors.textSecondaryLight,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: YaadColors.goldAccent),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'We couldn\'t perform this search.',
                      style: TextStyle(color: isDark ? YaadColors.textSecondaryDark : YaadColors.textSecondaryLight),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
