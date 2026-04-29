import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/speech_provider.dart';
import '../../providers/reading_provider.dart';
import '../../widgets/reading_text_view.dart';
import '../../widgets/mic_button.dart';
import '../../widgets/primary_button.dart';
import '../analytics/analytics_screen.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  Timer? _timer;
  Timer? _silenceTimer;
  bool _isListening = false;
  bool _hasNavigated = false;

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
    _silenceTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final provider = context.read<ReadingProvider>();
      if (provider.isTimerActive) {
        provider.updateTimerTick();
        
        if (provider.remainingSeconds <= 0 && !_hasNavigated) {
          _stopTimerAndNavigate(reason: 'Timer expired');
        }
      }
    });
  }

  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 3), () {
      if (_isListening && mounted && !_hasNavigated) {
        final speechProvider = context.read<SpeechProvider>();
        if (speechProvider.hasCapturedSpeech) {
          _stopTimerAndNavigate(reason: 'Silence detected');
        }
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
  }

  void _startListening() {
    final speechProvider = context.read<SpeechProvider>();
    final readingProvider = context.read<ReadingProvider>();

    _hasNavigated = false;
    readingProvider.startRecording();
    _startTimer();
    setState(() => _isListening = true);

    speechProvider.startListening(
      onFinalResult: (words) {
        if (!mounted || _hasNavigated) return;
        
        if (words.isNotEmpty) {
          readingProvider.updateLiveRecognized(words);
          final completed = readingProvider.updateLiveRecognized(words);
          if (completed) {
            _stopTimerAndNavigate(reason: 'Sentence completed');
          }
        }
      },
    );

    _startSilenceTimer();
  }

  void _stopListening() async {
    if (_hasNavigated) return;
    final speechProvider = context.read<SpeechProvider>();
    await speechProvider.stopListening();
    _stopTimerAndNavigate(reason: 'Manual stop');
  }

  void _stopTimerAndNavigate({String reason = ''}) {
    if (_hasNavigated) return;
    _hasNavigated = true;
    
    _stopTimer();
    final speechProvider = context.read<SpeechProvider>();
    final readingProvider = context.read<ReadingProvider>();
    
    readingProvider.stopTimer();
    setState(() => _isListening = false);

    final words = speechProvider.recognizedWords.isNotEmpty 
        ? speechProvider.recognizedWords 
        : speechProvider.partialWords;

    if (words.isNotEmpty && words.trim().isNotEmpty) {
      readingProvider.processResult(words);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AnalyticsScreen(),
          ),
        );
      }
    } else {
      if (mounted && speechProvider.isSessionLongEnough && speechProvider.hasCapturedSpeech) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No speech detected. Please try again.'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      speechProvider.reset();
    }
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mic,
                color: AppColors.successGreen,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Reading Test',
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
              
              _buildCompactHeader(),
              
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
              
              if (_isListening) _buildLiveTranscript(),
              
              const Spacer(),
              
              _buildMicSection(),
              
              const SizedBox(height: 24),
              
              Consumer<ReadingProvider>(
                builder: (context, readingProvider, child) {
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

  Widget _buildCompactHeader() {
    return Consumer<ReadingProvider>(
      builder: (context, provider, child) {
        final remaining = provider.remainingSeconds;
        final isWarning = remaining <= 5 && remaining > 0;
        
        if (_isListening) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isWarning 
                    ? AppColors.errorRed.withValues(alpha: 0.3)
                    : AppColors.textSecondary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: isWarning ? AppColors.errorRed : AppColors.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Time Left: ${_formatTime(remaining)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isWarning ? AppColors.errorRed : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: AppColors.successGreen,
                            size: 8,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Listening...',
                            style: TextStyle(
                              color: AppColors.successGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: remaining / provider.timerDuration,
                    backgroundColor: AppColors.textSecondary.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isWarning ? AppColors.errorRed : AppColors.primaryBlue,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }
        
        return GestureDetector(
          onTap: _showTimerPicker,
          child: Container(
            padding: const EdgeInsets.all(16),
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

  Widget _buildLiveTranscript() {
    return Consumer<SpeechProvider>(
      builder: (context, speechProvider, child) {
        final text = speechProvider.partialWords.isNotEmpty 
            ? speechProvider.partialWords 
            : speechProvider.recognizedWords;
        
        if (text.isEmpty) return const SizedBox.shrink();
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryBlue.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            '"$text"',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }

  Widget _buildMicSection() {
    return Consumer<SpeechProvider>(
      builder: (context, speechProvider, child) {
        final isActive = _isListening;
        
        return Column(
          children: [
            MicButton(
              isListening: isActive,
              onPressed: _isListening ? _stopListening : _startListening,
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
    return '${secs}s';
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