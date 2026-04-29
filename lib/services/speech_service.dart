import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  bool _speechStarted = false;
  DateTime? _lastSpeechTime;
  
  Function(String status)? _onStatusChanged;
  Function(String error)? _onError;
  Function(String words)? _onPartialResult;

  SpeechToText get engine => _speechToText;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    _isInitialized = await _speechToText.initialize(
      onError: (error) {
        if (error.permanent) {
          _isListening = false;
          _speechStarted = false;
          _onError?.call(error.errorMsg);
        }
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_isListening && !_speechStarted) {
            _isListening = false;
            _onStatusChanged?.call(status);
          }
        } else if (status == 'listening') {
          _speechStarted = true;
        }
      },
    );
    
    return _isInitialized;
  }

  void setCallbacks({
    Function(String status)? onStatusChanged,
    Function(String error)? onError,
    Function(String words)? onPartialResult,
  }) {
    _onStatusChanged = onStatusChanged;
    _onError = onError;
    _onPartialResult = onPartialResult;
  }

  Future<bool> startListening({
    required Function(String) onFinalResult,
    Function(String)? onPartialResult,
    Function()? onListeningStarted,
  }) async {
    final initialized = await initialize();
    if (!initialized) return false;
    
    _isListening = true;
    _speechStarted = false;
    _lastSpeechTime = null;
    
    await _speechToText.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          _lastSpeechTime = DateTime.now();
          if (!_speechStarted) {
            _speechStarted = true;
          }
        }
        
        if (result.finalResult) {
          _isListening = false;
          onFinalResult(result.recognizedWords);
        } else if (result.recognizedWords.isNotEmpty) {
          onPartialResult?.call(result.recognizedWords);
          _onPartialResult?.call(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 10),
      localeId: 'en_US',
      listenOptions: SpeechListenOptions(partialResults: true),
    );
    
    onListeningStarted?.call();
    return true;
  }

  Future<void> stopListening() async {
    _isListening = false;
    _speechStarted = false;
    await _speechToText.stop();
    _onStatusChanged?.call('done');
  }

  Future<void> cancel() async {
    _isListening = false;
    _speechStarted = false;
    await _speechToText.cancel();
    _onStatusChanged?.call('cancelled');
  }

  bool get isListening => _isListening;
  bool get hasSpeechStarted => _speechStarted;

  DateTime? get lastSpeechTime => _lastSpeechTime;

  Future<List<LocaleName>> getLocales() async {
    await initialize();
    return _speechToText.locales();
  }

  Future<void> dispose() async {
    await _speechToText.stop();
  }
}