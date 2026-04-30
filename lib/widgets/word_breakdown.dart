import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/word_match.dart';

class WordBreakdown extends StatelessWidget {
  final List<WordMatch> matches;
  final String expectedText;
  final Function(String word)? onWordTap;

  const WordBreakdown({
    super.key,
    required this.matches,
    required this.expectedText,
    this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (matches.isEmpty) {
      return _buildFallbackView(context);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.text_fields,
                    color: AppColors.primaryBlue,
                    size: 16,
                  ),
                ),
              const SizedBox(width: 8),
              const Text(
                'Word Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: matches.map((match) {
              return _buildWordChip(match, context);
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _buildFallbackView(BuildContext context) {
    final theme = Theme.of(context);
    final words = expectedText
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.text_fields,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Expected Text',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: words.map((word) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  word,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWordChip(WordMatch match, BuildContext context) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    bool isTappable = false;

    switch (match.status) {
      case WordMatchStatus.correct:
        backgroundColor = AppColors.successGreen.withValues(alpha: 0.15);
        textColor = AppColors.successGreen;
        borderColor = AppColors.successGreen.withValues(alpha: 0.3);
        break;
      case WordMatchStatus.wrong:
        backgroundColor = AppColors.errorRed.withValues(alpha: 0.15);
        textColor = AppColors.errorRed;
        borderColor = AppColors.errorRed.withValues(alpha: 0.3);
        isTappable = true;
        break;
      case WordMatchStatus.missed:
        backgroundColor = AppColors.warningOrange.withValues(alpha: 0.15);
        textColor = AppColors.warningOrange;
        borderColor = AppColors.warningOrange.withValues(alpha: 0.3);
        isTappable = true;
        break;
      case WordMatchStatus.pending:
        backgroundColor = theme.colorScheme.onSurface.withValues(alpha: 0.1);
        textColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
        borderColor = theme.colorScheme.onSurface.withValues(alpha: 0.2);
        break;
    }

    return GestureDetector(
        onTap: isTappable
            ? () {
                final word = match.heardWord ?? match.expectedWord;
                onWordTap?.call(word);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pronouncing: $word'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: theme.colorScheme.primary,
                  ),
                );
              }
            : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTappable) ...[
              Icon(
                Icons.volume_up,
                size: 12,
                color: textColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              match.heardWord ?? match.expectedWord,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.w500,
                decoration: match.status == WordMatchStatus.missed
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            if (match.status == WordMatchStatus.wrong && match.heardWord != null) ...[
              const SizedBox(width: 4),
              Text(
                '(${match.heardWord})',
                style: TextStyle(
                  fontSize: 11,
                  color: textColor.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (isTappable) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.touch_app,
                size: 12,
                color: textColor.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 16,
      children: [
        _LegendChip(
          color: AppColors.successGreen,
          label: 'Correct',
        ),
        _LegendChip(
          color: AppColors.errorRed,
          label: 'Wrong',
        ),
        _LegendChip(
          color: AppColors.warningOrange,
          label: 'Skipped',
        ),
        _LegendChip(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          label: 'Unread',
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendChip({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
