import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/word_match.dart';
import '../../models/reading_result.dart';
import '../../providers/reading_provider.dart';
import '../../widgets/score_card.dart';
import '../../widgets/primary_button.dart';
import '../reading/reading_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final result = context.read<ReadingProvider>().result;
      if (result != null && result.score >= 90) {
        setState(() => _showCelebration = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.primaryBlue,
              size: 18,
            ),
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
              return const Center(child: Text('No results available'));
            }

            final tips = ReadingResult.generateTips(result);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_showCelebration) _buildCelebration(),
                  _buildScoreCircle(result.score),
                  const SizedBox(height: 24),
                  _buildScoreCards(result),
                  const SizedBox(height: 20),
                  _buildTripleScore(result),
                  const SizedBox(height: 20),
_buildTimeCard(result.duration),
                  const SizedBox(height: 20),
                  _buildComparisonCard(result),
                  const SizedBox(height: 20),
                  if (result.mispronouncedWords.isNotEmpty ||
                      result.missedCount > 0)
                    _buildProblemWords(result),
                  const SizedBox(height: 20),
                  _buildTipsCard(tips),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Try Again',
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
                    label: const Text('Hear Correct'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildUpgradeButton(),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCelebration() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.successGreen.withValues(alpha: 0.2),
            AppColors.primaryBlue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: const Icon(
              Icons.emoji_events,
              size: 50,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Excellent!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.successGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCircle(double score) {
    Color scoreColor;
    if (score >= 90) {
      scoreColor = AppColors.successGreen;
    } else if (score >= 70) {
      scoreColor = AppColors.warningOrange;
    } else {
      scoreColor = AppColors.errorRed;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: scoreColor.withValues(alpha: 0.3),
              blurRadius: 25,
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
              'Accuracy',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCards(ReadingResult result) {
    return Row(
      children: [
        Expanded(
          child: ScoreCard(
            label: 'Correct',
            value: result.correctCount.toString(),
            icon: Icons.check_circle,
            color: AppColors.successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ScoreCard(
            label: 'Missed',
            value: result.missedCount.toString(),
            icon: Icons.remove_circle,
            color: AppColors.warningOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ScoreCard(
            label: 'Wrong',
            value: result.wrongCount.toString(),
            icon: Icons.cancel,
            color: AppColors.errorRed,
          ),
        ),
      ],
    );
  }

  Widget _buildTripleScore(ReadingResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ScoreColumn(
            label: 'Accuracy',
            value: '${result.score.toStringAsFixed(0)}%',
            color: result.score >= 80
                ? AppColors.successGreen
                : AppColors.warningOrange,
          ),
          _buildDivider(),
          _ScoreColumn(
            label: 'Completion',
            value: '${result.completionScore.toStringAsFixed(0)}%',
            color: result.completionScore >= 80
                ? AppColors.successGreen
                : AppColors.warningOrange,
          ),
          _buildDivider(),
          _ScoreColumn(
            label: 'Fluency',
            value: '${result.fluencyScore.toStringAsFixed(0)}%',
            color: result.fluencyScore >= 80
                ? AppColors.successGreen
                : AppColors.warningOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(ReadingResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
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
          const Text(
            'Comparison',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _ComparisonRow(
            label: 'Target',
            text: result.expectedText,
            color: AppColors.textPrimary,
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 8),
          _ComparisonRow(
            label: 'You Said',
            text: result.heardText,
            color: result.score >= 80 
                ? AppColors.successGreen 
                : AppColors.warningOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 50,
      color: AppColors.textSecondary.withValues(alpha: 0.2),
    );
  }

  Widget _buildTimeCard(Duration duration) {
    final provider = context.read<ReadingProvider>();
    final result = provider.result;
    if (result == null) return const SizedBox.shrink();
    
    final allocated = result.allocatedTime;
    final used = result.usedTime;
    
    final isFast = result.finishedEarly;
    final isTimeout = result.timedOut;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer, color: AppColors.primaryBlue, size: 24),
              const SizedBox(width: 12),
              Text(
                '$used sec used',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                ' / $allocated sec',
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (isFast || isTimeout) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isFast 
                    ? AppColors.successGreen.withValues(alpha: 0.1)
                    : AppColors.warningOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFast ? Icons.bolt : Icons.timer_off,
                    color: isFast ? AppColors.successGreen : AppColors.warningOrange,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isFast ? 'Fast Reader!' : 'Time Over',
                    style: TextStyle(
                      color: isFast ? AppColors.successGreen : AppColors.warningOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProblemWords(ReadingResult result) {
    final problems = result.wordMatches
        .where((m) =>
            m.status == WordMatchStatus.wrong || m.status == WordMatchStatus.missed)
        .toList();

    if (problems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
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
          const Text(
            'Words to Improve',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: problems.map((match) {
              final color = match.status == WordMatchStatus.missed
                  ? AppColors.warningOrange
                  : AppColors.errorRed;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  match.expectedWord,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(List<String> tips) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.primaryBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'Tips',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.take(3).map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(color: AppColors.textPrimary)),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.1),
            AppColors.primaryBlueDark.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.psychology, color: AppColors.primaryBlue, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Pro Analysis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Word-by-word pronunciation scoring',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warningOrange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String text;
  final Color color;

  const _ComparisonRow({
    required this.label,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '"$text"',
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}