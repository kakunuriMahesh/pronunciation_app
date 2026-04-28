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
  String _errorMessage = '';
  bool _isAvailable = false;

  SpeechState get state => _state;
  String get recognizedWords => _recognizedWords;
  String get errorMessage => _errorMessage;
  bool get isAvailable => _isAvailable;
  bool get isListening => _state == SpeechState.listening;

  Future<void> checkAvailability() async {
    _speechService.setCallbacks(
      onStatusChanged: (status) {
        if (status == 'done' || status == 'notListening' || status == 'ready') {
          if (_state == SpeechState.listening) {
            if (_recognizedWords.isNotEmpty) {
              _state = SpeechState.completed;
            } else {
              _state = SpeechState.idle;
            }
            notifyListeners();
          }
        }
      },
      onError: (error) {
        _state = SpeechState.error;
        _errorMessage = error;
        notifyListeners();
      },
    );
    
    _isAvailable = await _speechService.initialize();
    notifyListeners();
  }

  Future<void> startListening({required Function(String) onResult, Function()? onListeningStopped}) async {
    _state = SpeechState.listening;
    _recognizedWords = '';
    _errorMessage = '';
    notifyListeners();

    final success = await _speechService.startListening(
      onResult: (words) {
        _recognizedWords = words;
        _state = SpeechState.processing;
        notifyListeners();
      },
      onListeningStopped: onListeningStopped,
    );
    
    if (!success) {
      _state = SpeechState.error;
      _errorMessage = 'Failed to start listening';
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    await _speechService.stopListening();
    if (_recognizedWords.isNotEmpty) {
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
    notifyListeners();
  }

  void reset() {
    _state = SpeechState.idle;
    _recognizedWords = '';
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }
}