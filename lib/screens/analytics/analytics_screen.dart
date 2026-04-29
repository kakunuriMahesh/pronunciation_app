import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/reading_result.dart';
import '../../providers/reading_provider.dart';
import '../../widgets/result_metric_card.dart';
import '../../widgets/reading_chart.dart';
import '../../widgets/word_breakdown.dart';
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
  late Animation<double> _fadeAnimation;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
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
          'Reading Test Results',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showCelebration) _buildCelebration(),
                    _buildHeader(result),
                    const SizedBox(height: 24),
                    _buildTopMetrics(result),
                    const SizedBox(height: 20),
                    ReadingChart(provider: provider),
                    const SizedBox(height: 20),
                    WordBreakdown(
                      matches: result.wordMatches,
                      expectedText: result.expectedText,
                      onWordTap: (word) {
                        provider.speakWord(word);
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTranscriptSection(result),
                    const SizedBox(height: 20),
                    _buildPerformanceFeedback(tips),
                    const SizedBox(height: 24),
                    _buildActionButtons(provider),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ReadingResult result) {
    final scoreColor = result.score >= 90
        ? AppColors.successGreen
        : result.score >= 70
            ? AppColors.warningOrange
            : AppColors.errorRed;

    return Row(
      children: [
        ScaleTransition(
          scale: _fadeAnimation,
          child: Container(
            width: 80,
            height: 80,
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
                  result.score.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                const Text(
                  'SCORE',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getScoreLabel(result.score),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${result.correctCount}/${result.totalWords} words correct',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: result.score / 100,
                  backgroundColor: Colors.grey.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getScoreLabel(double score) {
    if (score >= 90) return 'Excellent!';
    if (score >= 80) return 'Great Job!';
    if (score >= 70) return 'Good Work!';
    if (score >= 60) return 'Keep Going!';
    return 'Practice More';
  }

  Widget _buildTopMetrics(ReadingResult result) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        ResultMetricCard(
          label: 'Accuracy',
          value: result.score.toStringAsFixed(0),
          unit: '%',
          icon: Icons.check_circle_outline,
          color: result.score >= 80 ? AppColors.successGreen : AppColors.warningOrange,
          progress: result.score,
        ),
        ResultMetricCard(
          label: 'Speed',
          value: result.wpm.toStringAsFixed(0),
          unit: 'WPM',
          icon: Icons.speed,
          color: AppColors.primaryBlue,
        ),
        ResultMetricCard(
          label: 'Completion',
          value: result.completionScore.toStringAsFixed(0),
          unit: '%',
          icon: Icons.done_all,
          color: result.completionScore >= 80
              ? AppColors.successGreen
              : AppColors.warningOrange,
          progress: result.completionScore,
        ),
        ResultMetricCard(
          label: 'Fluency',
          value: result.fluencyScore.toStringAsFixed(0),
          unit: '%',
          icon: Icons.waves,
          color: result.fluencyScore >= 80
              ? AppColors.successGreen
              : AppColors.warningOrange,
          progress: result.fluencyScore,
        ),
        ResultMetricCard(
          label: 'Time',
          value: result.usedTime.toString(),
          unit: 'sec',
          icon: Icons.timer,
          color: AppColors.textPrimary,
        ),
        ResultMetricCard(
          label: 'Mistakes',
          value: result.wrongCount.toString(),
          unit: 'words',
          icon: Icons.cancel_outlined,
          color: result.wrongCount == 0
              ? AppColors.successGreen
              : AppColors.errorRed,
        ),
      ],
    );
  }

  Widget _buildTranscriptSection(ReadingResult result) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.compare_arrows,
                  color: AppColors.primaryBlue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Transcript',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Expected:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '"${result.expectedText}"',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 16),
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'You Read:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (result.score >= 80)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '✓ Match',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '"${result.heardText}"',
                style: TextStyle(
                  fontSize: 15,
                  color: result.score >= 80
                      ? AppColors.successGreen
                      : AppColors.warningOrange,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceFeedback(List<String> tips) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.08),
            AppColors.primaryBlue.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.primaryBlue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Performance Feedback',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.take(4).map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.4,
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

  Widget _buildActionButtons(ReadingProvider provider) {
    return Column(
      children: [
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
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  provider.speakText();
                },
                icon: const Icon(Icons.volume_up, size: 18),
                label: const Text('Hear Correct'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  side: BorderSide(color: AppColors.primaryBlue),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  provider.reset();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const ReadingScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.skip_next, size: 18),
                label: const Text('Next Sentence'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  side: BorderSide(color: AppColors.successGreen),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCelebration() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.successGreen.withValues(alpha: 0.15),
            AppColors.primaryBlue.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _fadeAnimation,
            child: const Icon(
              Icons.emoji_events,
              size: 40,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Excellent Job!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.successGreen,
            ),
          ),
        ],
      ),
    );
  }
}