import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/speech_provider.dart';
import '../../providers/reading_provider.dart';
import '../../widgets/reading_text_view.dart';
import '../../widgets/mic_button.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/live_stats_card.dart';
import '../analytics/analytics_screen.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  Timer? _timer;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpeechProvider>().checkAvailability();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final provider = context.read<ReadingProvider>();
      if (provider.isTimerActive) {
        provider.updateTimerTick();
        
        if (provider.remainingSeconds <= 0) {
          _stopTimerAndNavigate();
        }
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _startListening() {
    final speechProvider = context.read<SpeechProvider>();
    final readingProvider = context.read<ReadingProvider>();

    readingProvider.startRecording();
    _startTimer();
    setState(() => _isListening = true);

    speechProvider.startListening(
      onResult: (words) {
        if (words.isNotEmpty) {
          readingProvider.updateLiveRecognized(words);
        }
      },
      onListeningStopped: () {
        if (mounted) {
          _stopTimerAndNavigate();
        }
      },
    );
  }

  void _stopListening() async {
    final speechProvider = context.read<SpeechProvider>();
    await speechProvider.stopListening();
    _stopTimerAndNavigate();
  }

  void _stopTimerAndNavigate() {
    _stopTimer();
    final speechProvider = context.read<SpeechProvider>();
    final readingProvider = context.read<ReadingProvider>();
    
    readingProvider.stopTimer();
    setState(() => _isListening = false);

    if (speechProvider.recognizedWords.isNotEmpty) {
      readingProvider.processResult(speechProvider.recognizedWords);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AnalyticsScreen(),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No speech detected. Please try again.'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    speechProvider.reset();
  }

  void _showTimerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TimerPickerSheet(
        currentDuration: context.read<ReadingProvider>().timerDuration,
        onSelect: (duration) {
          context.read<ReadingProvider>().setTimerDuration(duration);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
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
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mic,
                color: AppColors.successGreen,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'Free Mode',
                style: TextStyle(
                  color: AppColors.successGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              _buildTimerSection(),
              
              const SizedBox(height: 20),
              
              Consumer<ReadingProvider>(
                builder: (context, provider, child) {
                  return LiveStatsHeader(
                    correct: provider.correctCount,
                    wrong: provider.wrongCount,
                    remaining: provider.remainingCount,
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              Expanded(
                flex: 2,
                child: Consumer<ReadingProvider>(
                  builder: (context, provider, child) {
                    return ReadingTextView(
                      text: provider.currentText,
                      matches: provider.liveMatches,
                      showHighlights: provider.liveMatches.isNotEmpty,
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              Consumer<SpeechProvider>(
                builder: (context, speechProvider, child) {
                  if (speechProvider.recognizedWords.isNotEmpty) {
                    return _buildSpokenSentenceCard(speechProvider.recognizedWords);
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              const Spacer(),
              
              _buildMicSection(),
              
              const SizedBox(height: 24),
              
              Consumer2<SpeechProvider, ReadingProvider>(
                builder: (context, speechProvider, readingProvider, child) {
                  return PrimaryButton(
                    text: 'Hear Correct',
                    icon: Icons.volume_up,
                    onPressed: () {
                      readingProvider.speakText();
                    },
                  );
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    return Consumer<ReadingProvider>(
      builder: (context, provider, child) {
        final remaining = provider.remainingSeconds;
        final isWarning = remaining <= 5 && remaining > 0;
        
        if (_isListening) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isWarning 
                  ? AppColors.errorRed.withValues(alpha: 0.1)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isWarning 
                    ? AppColors.errorRed.withValues(alpha: 0.3)
                    : AppColors.textSecondary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer,
                  color: isWarning ? AppColors.errorRed : AppColors.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: isWarning ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: isWarning ? AppColors.errorRed : AppColors.textPrimary,
                  ),
                  child: Text(
                    _formatTime(remaining),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'remaining',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        
        return GestureDetector(
          onTap: _showTimerPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Reading Time: ${provider.timerDuration} sec',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpokenSentenceCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.2),
        ),
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
                  Icons.record_voice_over,
                  color: AppColors.primaryBlue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'You said:',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"$text"',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicSection() {
    return Consumer<SpeechProvider>(
      builder: (context, speechProvider, child) {
        final isActive = _isListening || speechProvider.isListening;
        
        return Column(
          children: [
            MicButton(
              isListening: isActive,
              onPressed: _startListening,
              onStopPressed: _stopListening,
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                isActive ? 'Tap to stop' : 'Tap to start',
                key: ValueKey(isActive),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins > 0) {
      return '$mins:${secs.toString().padLeft(2, '0')}';
    }
    return '00:${secs.toString().padLeft(2, '0')}';
  }
}

class _TimerPickerSheet extends StatelessWidget {
  final int currentDuration;
  final Function(int) onSelect;

  const _TimerPickerSheet({
    required this.currentDuration,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final options = [15, 30, 45, 60];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Reading Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ...options.map((duration) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => onSelect(duration),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: duration == currentDuration 
                      ? AppColors.primaryBlue.withValues(alpha: 0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: duration == currentDuration 
                        ? AppColors.primaryBlue
                        : AppColors.textSecondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      color: duration == currentDuration 
                          ? AppColors.primaryBlue 
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$duration seconds',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: duration == currentDuration 
                            ? AppColors.primaryBlue 
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}