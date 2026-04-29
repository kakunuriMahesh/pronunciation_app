import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/word_match.dart';

class ReadingTextView extends StatefulWidget {
  final String text;
  final List<WordMatch> matches;
  final bool showHighlights;

  const ReadingTextView({
    super.key,
    required this.text,
    this.matches = const [],
    this.showHighlights = false,
  });

  @override
  State<ReadingTextView> createState() => _ReadingTextViewState();
}

class _ReadingTextViewState extends State<ReadingTextView>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeController.forward();
  }

  @override
  void didUpdateWidget(ReadingTextView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.matches != oldWidget.matches) {
      _fadeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showHighlights || widget.matches.isEmpty) {
      return _buildSimpleText(context);
    }
    return _buildHighlightedText(context);
  }

  Widget _buildSimpleText(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(
            widget.text,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(BuildContext context) {
    final words = widget.text.split(' ');
    final spans = <InlineSpan>[];
    final theme = Theme.of(context);

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      Color textColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);
      Color? backgroundColor;
      FontWeight fontWeight = FontWeight.normal;

      if (i < widget.matches.length) {
        final match = widget.matches[i];
        switch (match.status) {
          case WordMatchStatus.correct:
            textColor = AppColors.successGreen;
            backgroundColor = AppColors.successGreen.withValues(alpha: 0.15);
            fontWeight = FontWeight.w600;
            break;
          case WordMatchStatus.wrong:
            textColor = AppColors.errorRed;
            backgroundColor = AppColors.errorRed.withValues(alpha: 0.15);
            fontWeight = FontWeight.w600;
            break;
          case WordMatchStatus.missed:
            textColor = AppColors.warningOrange;
            backgroundColor = AppColors.warningOrange.withValues(alpha: 0.15);
            fontWeight = FontWeight.w500;
            break;
          case WordMatchStatus.pending:
            textColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);
            break;
        }
      } else {
        textColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);
      }

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  word,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: fontWeight,
                    height: 1.4,
                  ),
                ),
              );
            },
          ),
        ),
      );

      if (i < words.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        runSpacing: 8,
        spacing: 4,
        children: List.generate(words.length, (i) {
          final word = words[i];
          Color textColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);
          Color? backgroundColor;

          if (i < widget.matches.length) {
            final match = widget.matches[i];
            switch (match.status) {
              case WordMatchStatus.correct:
                textColor = AppColors.successGreen;
                backgroundColor = AppColors.successGreen.withValues(alpha: 0.15);
                break;
              case WordMatchStatus.wrong:
                textColor = AppColors.errorRed;
                backgroundColor = AppColors.errorRed.withValues(alpha: 0.15);
                break;
              case WordMatchStatus.missed:
                textColor = AppColors.warningOrange;
                backgroundColor = AppColors.warningOrange.withValues(alpha: 0.15);
                break;
              case WordMatchStatus.pending:
                textColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);
                break;
            }
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              word,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: i < widget.matches.length &&
                        widget.matches[i].status == WordMatchStatus.correct
                    ? FontWeight.w600
                    : FontWeight.w500,
                height: 1.4,
              ),
            ),
          );
        }),
      ),
    );
  }
}