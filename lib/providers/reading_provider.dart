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

  // Advanced analytics
  List<WordTimestamp> _wordTimestamps = [];
  List<PauseEvent> _pauseEvents = [];
  int _restartCount = 0;
  int _partialTranscriptCount = 0;
  String _finalTranscript = '';
  Map<int, WordMatchStatus> _wordPositions = {};

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

  // Analytics getters
  List<WordTimestamp> get wordTimestamps => _wordTimestamps;
  List<PauseEvent> get pauseEvents => _pauseEvents;
  int get restartCount => _restartCount;
  int get partialTranscriptCount => _partialTranscriptCount;
  String get finalTranscript => _finalTranscript;
  Map<int, WordMatchStatus> get wordPositions => _wordPositions;

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
    _wordTimestamps = [];
    _pauseEvents = [];
    _restartCount = 0;
    _partialTranscriptCount = 0;
    _finalTranscript = '';
    _wordPositions = {};
    
    _remainingSeconds = _timerDuration;
    _isTimerActive = true;
    _timerCompleted = false;
    
    notifyListeners();
  }

  void restartRecording() {
    _restartCount++;
    _isTimerActive = true;
    notifyListeners();
  }

  bool updateLiveRecognized(String recognizedWords, {bool isPartial = false}) {
    if (_startTime == null) return false;
    
    if (isPartial) {
      _partialTranscriptCount++;
    }
    
    final now = DateTime.now();
    if (_lastWordTime != null) {
      final pauseDuration = now.difference(_lastWordTime!).inMilliseconds;
      if (pauseDuration > 2000) {
        _pauseCount++;
        _pauseEvents.add(PauseEvent(
          timestamp: now,
          durationMs: pauseDuration,
        ));
      }
    }
    _lastWordTime = now;

    final expectedWords = _tokenize(_currentText);
    final recognized = _tokenize(recognizedWords);
    
    _liveMatches = [];
    _wordPositions = {};

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
        
        _wordPositions[i] = status;
        
        if (status == WordMatchStatus.correct && i >= _wordTimestamps.length) {
          _wordTimestamps.add(WordTimestamp(
            word: expected,
            index: i,
            timestamp: now,
            status: status,
          ));
        }
      } else {
        _liveMatches.add(WordMatch(
          expectedWord: expectedWords[i],
          heardWord: null,
          status: WordMatchStatus.pending,
          index: i,
        ));
        _wordPositions[i] = WordMatchStatus.pending;
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

    // Check if sentence completed (95%+ words spoken correctly)
    final spokenCount = recognized.length;
    if (spokenCount >= expectedWords.length * 0.95 && _correctCount >= expectedWords.length * 0.95) {
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
    _finalTranscript = recognizedWords;

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

  Future<void> speakWord(String word) async {
    await _ttsService.speak(word);
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
    _wordTimestamps = [];
    _pauseEvents = [];
    _restartCount = 0;
    _partialTranscriptCount = 0;
    _finalTranscript = '';
    _wordPositions = {};
    notifyListeners();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}

class WordTimestamp {
  final String word;
  final int index;
  final DateTime timestamp;
  final WordMatchStatus status;

  WordTimestamp({
    required this.word,
    required this.index,
    required this.timestamp,
    required this.status,
  });
}

class PauseEvent {
  final DateTime timestamp;
  final int durationMs;

  PauseEvent({
    required this.timestamp,
    required this.durationMs,
  });
}