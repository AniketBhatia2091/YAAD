import 'package:flutter/material.dart';

import '../../app/theme/color_tokens.dart';
import '../../app/theme/radius_tokens.dart';
import '../../app/theme/spacing_tokens.dart';
import '../../app/theme/typography_tokens.dart';
import '../../core/services/understanding/understanding_field.dart';

class UnderstandingFieldCard extends StatefulWidget {
  final UnderstandingField field;
  final ValueChanged<UnderstandingField> onFieldChanged;
  final VoidCallback onFieldCleared;
  final VoidCallback? onFieldConfirmed;
  final bool isConfirmed;

  const UnderstandingFieldCard({
    super.key,
    required this.field,
    required this.onFieldChanged,
    required this.onFieldCleared,
    this.onFieldConfirmed,
    this.isConfirmed = false,
  });

  @override
  State<UnderstandingFieldCard> createState() => _UnderstandingFieldCardState();
}

class _UnderstandingFieldCardState extends State<UnderstandingFieldCard> {
  bool _isEditing = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.field.value ?? '');
  }

  @override
  void didUpdateWidget(covariant UnderstandingFieldCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.value != widget.field.value && !_isEditing) {
      _controller.text = widget.field.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveEdit() {
    final newValue = _controller.text.trim();
    // Rule: When user edits a field, confidence becomes unknown, source becomes visible.
    final updated = widget.field.copyWith(
      value: newValue.isEmpty ? null : newValue,
      confidence: FieldConfidence.unknown,
      source: FieldSource.visible,
    );
    widget.onFieldChanged(updated);
    setState(() {
      _isEditing = false;
    });
  }

  void _cancelEdit() {
    _controller.text = widget.field.value ?? '';
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final hasValue = field.value != null && field.value!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: YaadSpacing.sm),
      padding: YaadSpacing.cardPadding,
      decoration: BoxDecoration(
        color: YaadColors.surfaceLight,
        borderRadius: YaadRadius.borderLg,
        border: Border.all(
          color: widget.isConfirmed ? YaadColors.success : YaadColors.borderLight,
          width: widget.isConfirmed ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field Header (Label + Confirmed Checkmark)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                field.displayLabel,
                style: YaadTypography.labelSmall.copyWith(
                  color: YaadColors.textMutedLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.isConfirmed)
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: YaadColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Confirmed',
                      style: YaadTypography.labelSmall.copyWith(
                        color: YaadColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Editing State vs Display State
          if (_isEditing) ...[
            TextField(
              controller: _controller,
              autofocus: true,
              style: YaadTypography.titleMedium,
              decoration: InputDecoration(
                hintText: 'Enter ${field.displayLabel.toLowerCase()}',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _cancelEdit,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YaadColors.primary,
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ] else ...[
            // Value Display
            Text(
              hasValue ? field.value! : 'Not specified',
              style: hasValue
                  ? YaadTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: YaadColors.textPrimaryLight,
                    )
                  : YaadTypography.bodyMedium.copyWith(
                      color: YaadColors.textMutedLight,
                      fontStyle: FontStyle.italic,
                    ),
            ),
            const SizedBox(height: 8),

            // Metadata Badges (Confidence & Source)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildConfidenceBadge(field.confidence),
                _buildSourceBadge(field.source),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons: Edit, Clear, Confirm
            Row(
              children: [
                // Edit Button
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 34),
                  ),
                ),
                const SizedBox(width: 8),

                // Clear Button
                if (hasValue)
                  OutlinedButton.icon(
                    onPressed: widget.onFieldCleared,
                    icon: const Icon(Icons.clear_rounded, size: 16, color: YaadColors.textSecondaryLight),
                    label: const Text('Clear', style: TextStyle(color: YaadColors.textSecondaryLight)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 34),
                    ),
                  ),

                const Spacer(),

                // Confirm Button
                if (widget.onFieldConfirmed != null && !widget.isConfirmed)
                  ElevatedButton.icon(
                    onPressed: widget.onFieldConfirmed,
                    icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                    label: const Text('Confirm', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: YaadColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: const Size(0, 34),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(FieldConfidence confidence) {
    Color bg;
    Color fg;
    String label;

    switch (confidence) {
      case FieldConfidence.high:
        bg = YaadColors.successBg;
        fg = YaadColors.success;
        label = 'High confidence';
        break;
      case FieldConfidence.medium:
        bg = YaadColors.attentionWarningBg;
        fg = YaadColors.attentionWarning;
        label = 'Medium confidence';
        break;
      case FieldConfidence.low:
        bg = YaadColors.attentionUrgentBg;
        fg = YaadColors.attentionUrgent;
        label = 'Needs review';
        break;
      case FieldConfidence.unknown:
        bg = YaadColors.surfaceSubtleLight;
        fg = YaadColors.textSecondaryLight;
        label = 'User edited';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: YaadRadius.borderPill,
      ),
      child: Text(
        label,
        style: YaadTypography.labelSmall.copyWith(color: fg, fontSize: 11),
      ),
    );
  }

  Widget _buildSourceBadge(FieldSource source) {
    String label;
    switch (source) {
      case FieldSource.visible:
        label = 'Visible on document';
        break;
      case FieldSource.inferred:
        label = 'Inferred';
        break;
      case FieldSource.unknown:
        label = 'Unverified';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: const BoxDecoration(
        color: YaadColors.surfaceSubtleLight,
        borderRadius: YaadRadius.borderPill,
      ),
      child: Text(
        label,
        style: YaadTypography.labelSmall.copyWith(
          color: YaadColors.textSecondaryLight,
          fontSize: 11,
        ),
      ),
    );
  }
}
