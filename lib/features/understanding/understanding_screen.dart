import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/color_tokens.dart';
import '../../app/theme/radius_tokens.dart';
import '../../app/theme/shadow_tokens.dart';
import '../../app/theme/spacing_tokens.dart';
import '../../app/theme/typography_tokens.dart';
import '../../core/services/understanding/understanding_field.dart';
import '../../core/services/understanding/understanding_result.dart';
import '../../data/models/memory.dart';
import 'understanding_field_card.dart';

class UnderstandingScreen extends ConsumerStatefulWidget {
  final String memoryId;

  const UnderstandingScreen({
    super.key,
    required this.memoryId,
  });

  @override
  ConsumerState<UnderstandingScreen> createState() => _UnderstandingScreenState();
}

class _UnderstandingScreenState extends ConsumerState<UnderstandingScreen> {
  Memory? _memory;
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isSaving = false;
  UnderstandingResult? _result;
  List<UnderstandingField> _fields = [];
  final Set<String> _confirmedFieldNames = {};

  @override
  void initState() {
    super.initState();
    _loadMemoryAndUnderstand();
  }

  Future<void> _loadMemoryAndUnderstand() async {
    final repo = ref.read(memoryRepositoryProvider);
    final mem = await repo.getMemoryById(widget.memoryId);

    if (!mounted) return;

    if (mem == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _memory = mem;
      _isLoading = false;
      _isProcessing = true;
    });

    // If memory already has confirmed structured fields, load them directly
    if (mem.understandingStatus == UnderstandingStatus.confirmed &&
        mem.structuredFields.isNotEmpty) {
      setState(() {
        _fields = List.of(mem.structuredFields);
        _result = UnderstandingResult(
          status: UnderstandingStatus.confirmed,
          documentType: mem.documentType,
          categoryKey: mem.categoryKey,
          fields: mem.structuredFields,
          understoodAt: mem.understoodAt,
        );
        _isProcessing = false;
      });
      return;
    }

    // Run pluggable understanding service
    final service = ref.read(understandingServiceProvider);
    final result = await service.understand(mem);

    if (!mounted) return;

    setState(() {
      _result = result;
      _fields = List.of(result.fields);
      _isProcessing = false;
    });
  }

  Future<void> _onKeepMemory() async {
    if (_memory == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(memoryRepositoryProvider);
      final updated = _memory!.copyWith(
        understandingStatus: UnderstandingStatus.unknown,
        updatedAt: DateTime.now(),
      );
      await repo.updateMemory(updated);

      _invalidateProviders();

      if (mounted) {
        context.go('/memory/${widget.memoryId}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _onConfirmAndRemember() async {
    if (_memory == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(memoryRepositoryProvider);
      final confirmedResult = UnderstandingResult(
        status: UnderstandingStatus.confirmed,
        documentType: _result?.documentType ?? _memory!.documentType,
        categoryKey: _result?.categoryKey ?? _memory!.categoryKey,
        fields: _fields,
        overallConfidence: _result?.overallConfidence ?? 1.0,
        understoodAt: DateTime.now(),
      );

      await repo.updateUnderstanding(widget.memoryId, confirmedResult);

      _invalidateProviders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memory understood & confirmed.')),
        );
        context.go('/memory/${widget.memoryId}');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('YAAD couldn\'t confirm this memory right now. Please try again.')),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _invalidateProviders() {
    ref.invalidate(recentlyRememberedProvider);
    ref.invalidate(attentionItemsProvider);
    ref.invalidate(upcomingItemsProvider);
    ref.invalidate(vaultCategoriesProvider);
    ref.invalidate(searchResultsProvider);
    ref.invalidate(memoryByIdProvider(widget.memoryId));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: YaadColors.goldAccent)),
      );
    }

    if (_memory == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Understanding')),
        body: const Center(child: Text('Memory not found.')),
      );
    }

    final imageFile = _memory!.imagePath != null ? File(_memory!.imagePath!) : null;
    final hasValidImage = imageFile != null && imageFile.existsSync();
    final cardBg = isDark ? YaadColors.surfaceDark : YaadColors.surfaceLight;
    final borderColor = isDark ? YaadColors.borderDark : YaadColors.borderLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('YAAD Understanding'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/memory/${widget.memoryId}');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: YaadSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Image Thumbnail Container
                    if (hasValidImage)
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 200),
                        margin: const EdgeInsets.only(bottom: YaadSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark ? YaadColors.surfaceDark : Colors.black,
                          borderRadius: YaadRadius.borderLg,
                          border: Border.all(color: borderColor),
                          boxShadow: YaadShadows.subtle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.file(
                          imageFile,
                          fit: BoxFit.contain,
                        ),
                      ),

                    // State A: Processing state
                    if (_isProcessing) ...[
                      Container(
                        padding: YaadSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: YaadRadius.borderLg,
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: YaadColors.goldAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Understanding this memory…',
                                  style: YaadTypography.titleMediumOf(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Identifying document structure, key dates, and amounts.',
                              style: TextStyle(
                                color: isDark ? YaadColors.textSecondaryDark : YaadColors.textSecondaryLight,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_fields.isEmpty) ...[
                      // State C: Unknown / Unclassified state (No extracted fields)
                      Container(
                        padding: YaadSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: YaadRadius.borderLg,
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.help_outline_rounded,
                                  color: YaadColors.goldAccent,
                                  size: 26,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'YAAD couldn\'t understand this yet',
                                    style: YaadTypography.titleMediumOf(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your memory is safely saved. You can keep it in your vault and review it anytime.',
                              style: TextStyle(
                                color: isDark ? YaadColors.textSecondaryDark : YaadColors.textSecondaryLight,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: YaadSpacing.lg),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isSaving ? null : _onKeepMemory,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text('Keep memory'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _loadMemoryAndUnderstand,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: YaadColors.goldPrimary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text('Try again'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // State B: Needs Review (Extracted fields found)
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: YaadColors.goldAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Here\'s what YAAD found',
                            style: (isDark ? YaadTypography.titleLargeDark : YaadTypography.titleLarge).copyWith(fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review and edit extracted values before confirming.',
                        style: TextStyle(
                          color: isDark ? YaadColors.textSecondaryDark : YaadColors.textSecondaryLight,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: YaadSpacing.md),

                      // List of editable UnderstandingFieldCards
                      for (int i = 0; i < _fields.length; i++)
                        UnderstandingFieldCard(
                          field: _fields[i],
                          isConfirmed: _confirmedFieldNames.contains(_fields[i].fieldName),
                          onFieldChanged: (updated) {
                            setState(() {
                              _fields[i] = updated;
                            });
                          },
                          onFieldCleared: () {
                            setState(() {
                              _fields[i] = _fields[i].copyWith(
                                value: null,
                                confidence: FieldConfidence.unknown,
                                source: FieldSource.unknown,
                              );
                            });
                          },
                          onFieldConfirmed: () {
                            setState(() {
                              _confirmedFieldNames.add(_fields[i].fieldName);
                            });
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Confirmation Bar (Visible when fields are available)
            if (!_isProcessing && _fields.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(top: BorderSide(color: borderColor)),
                  boxShadow: YaadShadows.card,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: YaadSpacing.minTouchTarget,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _onConfirmAndRemember,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.verified_rounded, color: Colors.white),
                    label: Text(
                      _isSaving ? 'Saving…' : 'Confirm & Remember',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: YaadColors.goldPrimary,
                      shape: const RoundedRectangleBorder(borderRadius: YaadRadius.borderMd),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
