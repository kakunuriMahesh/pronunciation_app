import 'package:flutter/foundation.dart';
import '../services/speech_service.dart';

enum SpeechState {
  idle,
  listening,
  processing,
  completed,
  error,
}

class SpeechProvider extends ChangeNotifier {
  final SpeechService _speechService = SpeechService();
  
  SpeechState _state = SpeechState.idle;
  String _recognizedWords = '';
  String _partialWords = '';
  String _errorMessage = '';
  bool _isAvailable = false;
  DateTime? _sessionStartTime;
  bool _hasCapturedSpeech = false;

  SpeechState get state => _state;
  String get recognizedWords => _recognizedWords;
  String get partialWords => _partialWords;
  String get errorMessage => _errorMessage;
  bool get isAvailable => _isAvailable;
  bool get isListening => _state == SpeechState.listening;
  bool get hasCapturedSpeech => _hasCapturedSpeech;
  DateTime? get sessionStartTime => _sessionStartTime;

  Future<void> checkAvailability() async {
    _speechService.setCallbacks(
      onStatusChanged: (status) {
        // Only handle fatal status changes, not normal pauses
      },
      onError: (error) {
        _state = SpeechState.error;
        _errorMessage = error;
        notifyListeners();
      },
      onPartialResult: (words) {
        _partialWords = words;
        if (!_hasCapturedSpeech && words.isNotEmpty) {
          _hasCapturedSpeech = true;
        }
        notifyListeners();
      },
    );
    
    _isAvailable = await _speechService.initialize();
    notifyListeners();
  }

  Future<bool> startListening({required Function(String) onFinalResult}) async {
    _state = SpeechState.listening;
    _recognizedWords = '';
    _partialWords = '';
    _errorMessage = '';
    _hasCapturedSpeech = false;
    _sessionStartTime = DateTime.now();
    notifyListeners();

    final success = await _speechService.startListening(
      onFinalResult: (words) {
        _recognizedWords = words;
        if (words.isNotEmpty) {
          _hasCapturedSpeech = true;
        }
        _state = SpeechState.completed;
        notifyListeners();
        onFinalResult(words);
      },
      onPartialResult: (words) {
        _partialWords = words;
        if (words.isNotEmpty && !_hasCapturedSpeech) {
          _hasCapturedSpeech = true;
        }
        notifyListeners();
      },
    );
    
    if (!success) {
      _state = SpeechState.error;
      _errorMessage = 'Failed to start listening';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> stopListening() async {
    await _speechService.stopListening();
    if (_recognizedWords.isNotEmpty || _partialWords.isNotEmpty) {
      _recognizedWords = _recognizedWords.isEmpty ? _partialWords : _recognizedWords;
      _state = SpeechState.completed;
    } else {
      _state = SpeechState.idle;
    }
    notifyListeners();
  }

  Future<void> cancelListening() async {
    await _speechService.cancel();
    _state = SpeechState.idle;
    _recognizedWords = '';
    _partialWords = '';
    _hasCapturedSpeech = false;
    notifyListeners();
  }

  bool get isSessionLongEnough {
    if (_sessionStartTime == null) return false;
    final duration = DateTime.now().difference(_sessionStartTime!);
    return duration.inSeconds >= 2;
  }

  void reset() {
    _state = SpeechState.idle;
    _recognizedWords = '';
    _partialWords = '';
    _errorMessage = '';
    _hasCapturedSpeech = false;
    _sessionStartTime = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }
}