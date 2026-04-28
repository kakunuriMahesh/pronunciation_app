import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  
  Function(String status)? _onStatusChanged;
  Function(String error)? _onError;

  SpeechToText get engine => _speechToText;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    _isInitialized = await _speechToText.initialize(
      onError: (error) {
        _isListening = false;
        _onError?.call(error.errorMsg);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening' || status == 'ready') {
          _isListening = false;
          _onStatusChanged?.call(status);
        }
      },
    );
    
    return _isInitialized;
  }

  void setCallbacks({
    Function(String status)? onStatusChanged,
    Function(String error)? onError,
  }) {
    _onStatusChanged = onStatusChanged;
    _onError = onError;
  }

  Future<bool> startListening({
    required Function(String) onResult,
    Function()? onListeningStarted,
    Function()? onListeningStopped,
  }) async {
    final initialized = await initialize();
    if (!initialized) return false;
    
    _isListening = true;
    
    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          _isListening = false;
          onResult(result.recognizedWords);
          onListeningStopped?.call();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
    
    onListeningStarted?.call();
    return true;
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
    _onStatusChanged?.call('done');
  }

  Future<void> cancel() async {
    await _speechToText.cancel();
    _isListening = false;
    _onStatusChanged?.call('cancelled');
  }

  bool get isListening => _isListening;

  Future<List<LocaleName>> getLocales() async {
    await initialize();
    return _speechToText.locales();
  }

  Future<void> dispose() async {
    await _speechToText.stop();
  }
}