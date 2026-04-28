import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/word_match.dart';
import '../../providers/reading_provider.dart';
import '../../widgets/score_card.dart';
import '../../widgets/result_row.dart';
import '../../widgets/primary_button.dart';
import '../reading/reading_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            context.read<ReadingProvider>().reset();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
          ),
        ),
        title: const Text(
          'Results',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<ReadingProvider>(
          builder: (context, provider, child) {
            final result = provider.result;
            if (result == null) {
              return const Center(
                child: Text('No results available'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildScoreCircle(result.score),
                  const SizedBox(height: 24),
                  _buildScoreCards(result.correctCount, result.missedCount,
                      result.wrongCount),
                  const SizedBox(height: 24),
                  _buildStatsRow(result.wpm, result.fluencyText),
                  const SizedBox(height: 24),
                  _buildMatchesList(result.wordMatches),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Practice Again',
                    icon: Icons.replay,
                    onPressed: () {
                      provider.reset();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const ReadingScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      provider.speakText();
                    },
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Hear Correct Reading'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Unlock AI Pro Analysis'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warningOrange,
                      side: const BorderSide(
                        color: AppColors.warningOrange,
                        width: 1.5,
                      ),
                      minimumSize: const Size(double.infinity, 54),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScoreCircle(double score) {
    Color scoreColor;
    if (score >= 80) {
      scoreColor = AppColors.successGreen;
    } else if (score >= 50) {
      scoreColor = AppColors.warningOrange;
    } else {
      scoreColor = AppColors.errorRed;
    }

    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${score.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
          const Text(
            'Score',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCards(int correct, int missed, int wrong) {
    return Row(
      children: [
        Expanded(
          child: ScoreCard(
            label: 'Correct',
            value: correct.toString(),
            icon: Icons.check_circle,
            color: AppColors.successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ScoreCard(
            label: 'Missed',
            value: missed.toString(),
            icon: Icons.remove_circle,
            color: AppColors.errorRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ScoreCard(
            label: 'Wrong',
            value: wrong.toString(),
            icon: Icons.cancel,
            color: AppColors.warningOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(double wpm, String fluency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                wpm.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const Text(
                'WPM',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          Column(
            children: [
              Text(
                fluency,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const Text(
                'Fluency',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList(List<WordMatch> matches) {
    final wrongMatches = matches
        .where((m) => m.status != WordMatchStatus.correct && m.expectedWord.isNotEmpty)
        .toList();

    if (wrongMatches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.successGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.successGreen),
            SizedBox(width: 8),
            Text(
              'Perfect! All words correct.',
              style: TextStyle(
                color: AppColors.successGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expected vs Heard',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...wrongMatches.map(
          (match) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ResultRow(
              expected: match.expectedWord,
              heard: match.heardWord ?? '(missed)',
              statusColor: match.status == WordMatchStatus.missed
                  ? AppColors.errorRed
                  : AppColors.warningOrange,
            ),
          ),
        ),
      ],
    );
  }
}