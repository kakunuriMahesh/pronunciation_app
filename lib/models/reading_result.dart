import 'word_match.dart';

enum FluencyLevel {
  excellent,
  good,
  needsImprovement,
  poor,
}

class ReadingResult {
  final String expectedText;
  final String heardText;
  final List<WordMatch> wordMatches;
  final int correctCount;
  final int missedCount;
  final int wrongCount;
  final double score;
  final double wpm;
  final FluencyLevel fluency;
  final Duration duration;
  final int pauseCount;
  final int repeatedWords;
  final List<String> tips;
  final int allocatedTime;
  final int usedTime;

  ReadingResult({
    required this.expectedText,
    required this.heardText,
    required this.wordMatches,
    required this.correctCount,
    required this.missedCount,
    required this.wrongCount,
    required this.score,
    required this.wpm,
    required this.fluency,
    required this.duration,
    this.pauseCount = 0,
    this.repeatedWords = 0,
    this.tips = const [],
    this.allocatedTime = 30,
    this.usedTime = 0,
  });

  int get totalWords => wordMatches.length;
  
  double get completionScore {
    if (totalWords == 0) return 0;
    return (correctCount + wrongCount) / totalWords * 100;
  }
  
  double get fluencyScore {
    final baseScore = 100.0;
    final pausePenalty = pauseCount * 5.0;
    final repeatPenalty = repeatedWords * 8.0;
    final speedBonus = wpm > 80 && wpm < 150 ? 10.0 : 0.0;
    return (baseScore - pausePenalty - repeatPenalty + speedBonus).clamp(0, 100);
  }
  
  List<String> get mispronouncedWords {
    return wordMatches
        .where((m) => m.status == WordMatchStatus.wrong)
        .map((m) => m.expectedWord)
        .toList();
  }
  
  List<String> get missedWordsList {
    return wordMatches
        .where((m) => m.status == WordMatchStatus.missed)
        .map((m) => m.expectedWord)
        .toList();
  }
  
  int get remainingTime => allocatedTime - usedTime;
  
  bool get finishedEarly => usedTime < allocatedTime && correctCount >= totalWords * 0.8;
  
  bool get timedOut => usedTime >= allocatedTime;

  factory ReadingResult.empty() {
    return ReadingResult(
      expectedText: '',
      heardText: '',
      wordMatches: [],
      correctCount: 0,
      missedCount: 0,
      wrongCount: 0,
      score: 0,
      wpm: 0,
      fluency: FluencyLevel.poor,
      duration: Duration.zero,
      pauseCount: 0,
      repeatedWords: 0,
      tips: [],
      allocatedTime: 30,
      usedTime: 0,
    );
  }
  
  static List<String> generateTips(ReadingResult result) {
    final tips = <String>[];
    
    if (result.usedTime < result.allocatedTime * 0.5 && result.correctCount >= result.totalWords * 0.9) {
      tips.add('⚡ Great speed! You read very fast');
    }
    
    if (result.wpm < 60) {
      tips.add('Try to speak a bit faster');
    } else if (result.wpm > 160) {
      tips.add('Speak a little slower for better clarity');
    }
    
    if (result.pauseCount > 3) {
      tips.add('Try to minimize pauses between words');
    }
    
    if (result.repeatedWords > 2) {
      tips.add('Avoid repeating words - speak confidently');
    }
    
    if (result.missedCount > result.totalWords * 0.3) {
      tips.add('Don\'t skip words - read every word');
    }
    
    if (result.wrongCount > result.totalWords * 0.2) {
      final wrongWord = result.mispronouncedWords.firstOrNull;
      if (wrongWord != null) {
        tips.add('Focus on "$wrongWord" - say it clearly');
      }
    }
    
    if (result.finishedEarly) {
      tips.add('🔥 Fast reader! Great time management');
    }
    
    if (result.timedOut) {
      tips.add('⏰ Time ran out - try to speed up slightly');
    }
    
    if (result.fluency == FluencyLevel.excellent || result.score >= 90) {
      tips.add('⭐ Excellent! Keep up the great work');
    } else if (result.score >= 70) {
      tips.add('👍 Good effort! Practice more to improve');
    } else {
      tips.add('💪 Practice daily for best results');
    }
    
    return tips;
  }

  String get fluencyText {
    switch (fluency) {
      case FluencyLevel.excellent:
        return 'Excellent';
      case FluencyLevel.good:
        return 'Good';
      case FluencyLevel.needsImprovement:
        return 'Needs Improvement';
      case FluencyLevel.poor:
        return 'Poor';
    }
  }

  @override
  String toString() {
    return 'ReadingResult(score: ${score.toStringAsFixed(1)}%, wpm: ${wpm.toStringAsFixed(1)})';
  }
}