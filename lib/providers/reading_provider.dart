import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/reading_result.dart';
import '../models/word_match.dart';
import '../services/tts_service.dart';
import '../services/comparison_service.dart';

class ReadingProvider extends ChangeNotifier {
  final TtsService _ttsService = TtsService();
  final ComparisonService _comparisonService = ComparisonService();

  String _currentText = AppConstants.defaultReadingText;
  ReadingResult? _result;
  List<WordMatch> _liveMatches = [];
  bool _isPlaying = false;
  DateTime? _startTime;
  DateTime? _lastWordTime;
  double _speechRate = AppConstants.defaultSpeechRate;
  bool _autoStopEnabled = true;
  
  int _correctCount = 0;
  int _wrongCount = 0;
  int _missedCount = 0;
  int _pauseCount = 0;
  int _repeatedWords = 0;
  
  // Timer features
  int _timerDuration = 30;
  int _remainingSeconds = 30;
  bool _isTimerActive = false;
  bool _timerCompleted = false;

  String get currentText => _currentText;
  ReadingResult? get result => _result;
  List<WordMatch> get liveMatches => _liveMatches;
  bool get isPlaying => _isPlaying;
  double get speechRate => _speechRate;
  bool get autoStopEnabled => _autoStopEnabled;
  bool get isTimerActive => _isTimerActive;
  bool get isTimerCompleted => _timerCompleted;
  
  int get timerDuration => _timerDuration;
  int get remainingSeconds => _remainingSeconds;
  
  int get correctCount => _correctCount;
  int get wrongCount => _wrongCount;
  int get missedCount => _missedCount;
  int get remainingCount => _getRemainingCount();
  int get pauseCount => _pauseCount;
  int get repeatedWords => _repeatedWords;
  Duration get elapsedTime => _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;
  
  int get usedTime => _timerDuration - _remainingSeconds;
  bool get finishedEarly => _timerCompleted && _remainingSeconds > 0;
  bool get timedOut => _isTimerActive && _remainingSeconds <= 0;

  int _getRemainingCount() {
    final expectedWords = _tokenize(_currentText);
    return expectedWords.length - _correctCount - _wrongCount;
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  void setText(String text) {
    _currentText = text;
    _result = null;
    _liveMatches = [];
    reset();
    notifyListeners();
  }

  void setTimerDuration(int seconds) {
    _timerDuration = seconds;
    _remainingSeconds = seconds;
    notifyListeners();
  }

  void setAutoStop(bool enabled) {
    _autoStopEnabled = enabled;
    notifyListeners();
  }

  void updateTimerTick() {
    if (_isTimerActive && _remainingSeconds > 0) {
      _remainingSeconds--;
      if (_remainingSeconds <= 0) {
        _timerCompleted = true;
        _isTimerActive = false;
      }
      notifyListeners();
    }
  }

  void startRecording() {
    _startTime = DateTime.now();
    _lastWordTime = _startTime;
    _liveMatches = [];
    _correctCount = 0;
    _wrongCount = 0;
    _missedCount = 0;
    _pauseCount = 0;
    _repeatedWords = 0;
    
    _remainingSeconds = _timerDuration;
    _isTimerActive = true;
    _timerCompleted = false;
    
    notifyListeners();
  }

  bool updateLiveRecognized(String recognizedWords) {
    if (_startTime == null) return false;
    
    final now = DateTime.now();
    if (_lastWordTime != null && now.difference(_lastWordTime!).inMilliseconds > 2000) {
      _pauseCount++;
    }
    _lastWordTime = now;

    final expectedWords = _tokenize(_currentText);
    final recognized = _tokenize(recognizedWords);
    
    _liveMatches = [];

    for (int i = 0; i < expectedWords.length; i++) {
      final expected = expectedWords[i];
      
      if (i < recognized.length) {
        final heard = recognized[i];
        
        WordMatchStatus status;
        if (expected == heard) {
          status = WordMatchStatus.correct;
        } else if (_fuzzyMatch(expected, heard)) {
          status = WordMatchStatus.correct;
        } else {
          status = WordMatchStatus.wrong;
        }

        _liveMatches.add(WordMatch(
          expectedWord: expected,
          heardWord: heard,
          status: status,
          index: i,
        ));
      } else {
        _liveMatches.add(WordMatch(
          expectedWord: expectedWords[i],
          heardWord: null,
          status: WordMatchStatus.pending,
          index: i,
        ));
      }
    }

    _correctCount = _liveMatches.where((m) => m.status == WordMatchStatus.correct).length;
    _wrongCount = _liveMatches.where((m) => m.status == WordMatchStatus.wrong).length;
    _missedCount = _liveMatches.where((m) => m.status == WordMatchStatus.pending).length;

    for (int i = 0; i < recognized.length && i < expectedWords.length; i++) {
      int repetitions = 0;
      for (int j = i + 1; j < recognized.length; j++) {
        if (recognized[i] == recognized[j]) repetitions++;
      }
      if (repetitions > 0) {
        _repeatedWords += repetitions;
      }
    }

    notifyListeners();

    // Check if sentence completed (90%+ words spoken)
    final spokenCount = recognized.length;
    if (spokenCount >= expectedWords.length * 0.9 && spokenCount > 0) {
      return true;
    }
    
    // Check if timer ran out
    if (_timerCompleted) {
      return true;
    }
    
    return false;
  }

  bool _fuzzyMatch(String expected, String heard) {
    if (expected.isEmpty || heard.isEmpty) return false;
    if (expected == heard) return true;
    
    final maxLen = expected.length > heard.length ? expected.length : heard.length;
    if (maxLen == 0) return false;
    
    int matches = 0;
    for (int i = 0; i < expected.length && i < heard.length; i++) {
      if (expected[i] == heard[i]) matches++;
    }
    
    return matches / maxLen >= 0.7;
  }

  void processResult(String recognizedWords) {
    _startTime ??= DateTime.now();

    final duration = DateTime.now().difference(_startTime!);
    final matches = _comparisonService.compare(_currentText, recognizedWords);

    _result = _comparisonService.createResult(
      expectedText: _currentText,
      heardText: recognizedWords,
      matches: matches,
      duration: duration,
      pauseCount: _pauseCount,
      repeatedWords: _repeatedWords,
      allocatedTime: _timerDuration,
      usedTime: _timerDuration - _remainingSeconds,
    );

    _liveMatches = matches;
    notifyListeners();
  }

  Future<void> speakText() async {
    _isPlaying = true;
    notifyListeners();

    await _ttsService.speak(_currentText);

    _isPlaying = false;
    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    await _ttsService.stop();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _ttsService.setSpeechRate(rate);
    notifyListeners();
  }

  void stopTimer() {
    _isTimerActive = false;
    notifyListeners();
  }

  void reset() {
    _result = null;
    _liveMatches = [];
    _startTime = null;
    _lastWordTime = null;
    _correctCount = 0;
    _wrongCount = 0;
    _missedCount = 0;
    _pauseCount = 0;
    _repeatedWords = 0;
    _remainingSeconds = _timerDuration;
    _isTimerActive = false;
    _timerCompleted = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}