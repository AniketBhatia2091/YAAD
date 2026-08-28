import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/color_tokens.dart';
import '../../app/theme/radius_tokens.dart';
import '../../app/theme/shadow_tokens.dart';
import '../../app/theme/spacing_tokens.dart';
import '../../app/theme/typography_tokens.dart';

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

    return Scaffold(
      backgroundColor: YaadColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: YaadSpacing.md, vertical: YaadSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Headline
              Text(
                'Find anything you\'ve remembered.',
                style: YaadTypography.displayLarge.copyWith(letterSpacing: -0.5),
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
                  prefixIcon: const Icon(Icons.search_rounded, color: YaadColors.textSecondaryLight),
                  suffixIcon: currentQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: YaadColors.textMutedLight),
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
                        selectedColor: YaadColors.primary,
                        backgroundColor: YaadColors.surfaceLight,
                        labelStyle: YaadTypography.labelSmall.copyWith(
                          color: isSelected ? Colors.white : YaadColors.textPrimaryLight,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: YaadRadius.borderPill,
                          side: BorderSide(
                            color: isSelected ? YaadColors.primary : YaadColors.borderLight,
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
                            const Icon(Icons.search_off_rounded, size: 48, color: YaadColors.textMutedLight),
                            const SizedBox(height: 12),
                            Text(
                              'No memories matched "$currentQuery"',
                              style: YaadTypography.bodyLarge,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: memories.length,
                      itemBuilder: (context, index) {
                        final memory = memories[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: YaadSpacing.sm),
                          child: InkWell(
                            onTap: () => context.push('/memory/${memory.id}'),
                            borderRadius: YaadRadius.borderLg,
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
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      color: YaadColors.surfaceSubtleLight,
                                      borderRadius: YaadRadius.borderMd,
                                    ),
                                    child: Icon(
                                      memory.imagePath != null ? Icons.image_outlined : Icons.description_outlined,
                                      color: YaadColors.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          memory.title,
                                          style: YaadTypography.titleMedium,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          memory.subtitle ?? memory.documentType,
                                          style: YaadTypography.bodyMedium.copyWith(
                                            color: YaadColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: const BoxDecoration(
                                      color: YaadColors.surfaceSubtleLight,
                                      borderRadius: YaadRadius.borderPill,
                                    ),
                                    child: Text(
                                      memory.owner,
                                      style: YaadTypography.labelSmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const Center(child: Text('Error loading search results')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
