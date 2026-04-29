import 'package:flutter_tts/flutter_tts.dart';
import '../core/constants/app_constants.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String _selectedGender = 'female';

  FlutterTts get engine => _flutterTts;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(AppConstants.defaultSpeechRate);
    await _flutterTts.setPitch(AppConstants.defaultPitch);
    await _flutterTts.setVolume(AppConstants.defaultVolume);
    
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });
    
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });
    
    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
    });
    
    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
    });
    
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    await initialize();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  Future<List<dynamic>> getVoices() async {
    await initialize();
    return await _flutterTts.getVoices;
  }

  Future<void> setVoiceGender(String gender) async {
    await initialize();
    _selectedGender = gender;
    
    try {
      final voices = await getVoices();
      final enVoices = voices.where((v) {
        final locale = v['locale']?.toString() ?? '';
        return locale.startsWith('en');
      }).toList();
      
      if (gender == 'male') {
        // Try to find a male voice
        String? maleVoice;
        for (final voice in enVoices) {
          final name = voice['name']?.toString().toLowerCase() ?? '';
          if (name.contains('male') || name.contains('david') || name.contains('mark') || name.contains('alex') || name.contains('daniel') || name.contains('tom')) {
            maleVoice = voice['name'];
            break;
          }
        }
        
        if (maleVoice != null) {
          await _flutterTts.setVoice({'name': maleVoice, 'locale': 'en-US'});
        }
        // Lower pitch for male sound
        await _flutterTts.setPitch(0.7);
        await _flutterTts.setSpeechRate(AppConstants.defaultSpeechRate * 0.95);
      } else {
        // Try to find a female voice
        String? femaleVoice;
        for (final voice in enVoices) {
          final name = voice['name']?.toString().toLowerCase() ?? '';
          if (name.contains('female') || name.contains('samantha') || name.contains('karen') || name.contains('victoria') || name.contains('zira')) {
            femaleVoice = voice['name'];
            break;
          }
        }
        
        if (femaleVoice != null) {
          await _flutterTts.setVoice({'name': femaleVoice, 'locale': 'en-US'});
        }
        // Higher pitch for female sound
        await _flutterTts.setPitch(1.2);
        await _flutterTts.setSpeechRate(AppConstants.defaultSpeechRate);
      }
    } catch (e) {
      // Fallback to pitch adjustment if voice selection fails
      if (gender == 'male') {
        await _flutterTts.setPitch(0.7);
        await _flutterTts.setSpeechRate(AppConstants.defaultSpeechRate * 0.95);
      } else {
        await _flutterTts.setPitch(1.2);
        await _flutterTts.setSpeechRate(AppConstants.defaultSpeechRate);
      }
    }
  }

  String get selectedGender => _selectedGender;
  bool get isSpeaking => _isSpeaking;

  Future<void> dispose() async {
    await _flutterTts.stop();
  }
}