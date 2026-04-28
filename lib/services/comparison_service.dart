import '../core/utils/text_utils.dart';
import '../models/word_match.dart';
import '../models/reading_result.dart';

class ComparisonService {
  List<WordMatch> compare(String expectedText, String heardText) {
    final expectedWords = TextUtils.tokenize(expectedText);
    final heardWords = TextUtils.tokenize(heardText);
    
    final List<WordMatch> matches = [];
    
    for (int i = 0; i < expectedWords.length; i++) {
      final expected = expectedWords[i];
      
      if (i < heardWords.length) {
        final heard = heardWords[i];
        final expectedClean = expected.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        final heardClean = heard.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        
        WordMatchStatus status;
        if (expectedClean == heardClean) {
          status = WordMatchStatus.correct;
        } else if (_fuzzyMatch(expectedClean, heardClean)) {
          status = WordMatchStatus.correct;
        } else {
          status = WordMatchStatus.wrong;
        }
        
        matches.add(WordMatch(
          expectedWord: expected,
          heardWord: heard,
          status: status,
          index: i,
        ));
      } else {
        matches.add(WordMatch(
          expectedWord: expected,
          heardWord: null,
          status: WordMatchStatus.missed,
          index: i,
        ));
      }
    }
    
    for (int i = expectedWords.length; i < heardWords.length; i++) {
      matches.add(WordMatch(
        expectedWord: '',
        heardWord: heardWords[i],
        status: WordMatchStatus.wrong,
        index: i,
      ));
    }
    
    return matches;
  }
  
  bool _fuzzyMatch(String expected, String heard) {
    if (expected.isEmpty || heard.isEmpty) return false;
    
    if (expected == heard) return true;
    
    if (expected.length - heard.length > 2 || heard.length - expected.length > 2) return false;
    final maxLen = expected.length > heard.length ? expected.length : heard.length;
    int matches = 0;
    for (int i = 0; i < expected.length && i < heard.length; i++) {
      if (expected[i] == heard[i]) matches++;
    }
    
    return matches / maxLen >= 0.7;
  }

  ReadingResult createResult({
    required String expectedText,
    required String heardText,
    required List<WordMatch> matches,
    required Duration duration,
    int pauseCount = 0,
    int repeatedWords = 0,
    int allocatedTime = 30,
    int usedTime = 0,
  }) {
    int correctCount = 0;
    int missedCount = 0;
    int wrongCount = 0;
    
    for (final match in matches) {
      switch (match.status) {
        case WordMatchStatus.correct:
          correctCount++;
          break;
        case WordMatchStatus.missed:
          missedCount++;
          break;
        case WordMatchStatus.wrong:
          wrongCount++;
          break;
        case WordMatchStatus.pending:
          break;
      }
    }
    
    final totalWords = matches.where((m) => m.expectedWord.isNotEmpty).length;
    final score = totalWords > 0 ? (correctCount / totalWords) * 100 : 0.0;
    
    final wordCount = heardText.isNotEmpty ? TextUtils.tokenize(heardText).length : 0;
    final wpm = TextUtils.calculateWpm(wordCount, duration);
    
    final fluency = _calculateFluency(duration, matches.length);
    
    final result = ReadingResult(
      expectedText: expectedText,
      heardText: heardText,
      wordMatches: matches,
      correctCount: correctCount,
      missedCount: missedCount,
      wrongCount: wrongCount,
      score: score,
      wpm: wpm,
      fluency: fluency,
      duration: duration,
      pauseCount: pauseCount,
      repeatedWords: repeatedWords,
      allocatedTime: allocatedTime,
      usedTime: usedTime,
    );
    
    return result;
  }

  FluencyLevel _calculateFluency(Duration duration, int wordCount) {
    if (wordCount == 0) return FluencyLevel.poor;
    
    final secondsPerWord = duration.inSeconds / wordCount;
    
    if (secondsPerWord < 0.3) {
      return FluencyLevel.excellent;
    } else if (secondsPerWord < 0.5) {
      return FluencyLevel.good;
    } else if (secondsPerWord < 0.8) {
      return FluencyLevel.needsImprovement;
    } else {
      return FluencyLevel.poor;
    }
  }
}