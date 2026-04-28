import 'package:flutter/material.dart';

abstract class PremiumService {
  Future<bool> isPremium();
  Future<void> unlockFeature(PremiumFeature feature);
  Future<List<PremiumFeature>> getUnlockedFeatures();
  Future<void> checkSubscriptionStatus();
}

enum PremiumFeature {
  aiPronunciationScore,
  accentDetection,
  americanAccent,
  britishAccent,
  voiceReplay,
  dailyChallenges,
  progressCharts,
  unlimitedPractice,
  kidsMode,
  ieltsMode,
  interviewMode,
}

class PremiumServiceImpl implements PremiumService {
  final Map<PremiumFeature, bool> _unlockedFeatures = {};
  
  @override
  Future<bool> isPremium() async {
    return _unlockedFeatures.isNotEmpty;
  }
  
  @override
  Future<void> unlockFeature(PremiumFeature feature) async {
    _unlockedFeatures[feature] = true;
  }
  
  @override
  Future<List<PremiumFeature>> getUnlockedFeatures() async {
    return _unlockedFeatures.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
  }
  
  @override
  Future<void> checkSubscriptionStatus() async {}
}

class PremiumAnalytics {
  final PremiumService _premiumService = PremiumServiceImpl();
  
  Future<Map<String, dynamic>> getDetailedAnalysis(String audioPath) async {
    final isPremium = await _premiumService.isPremium();
    
    if (!isPremium) {
      throw PremiumRequiredException(
        'Upgrade to AI Pro for detailed word-by-word analysis',
      );
    }
    
    return {
      'wordScores': <Map<String, dynamic>>[],
      'phonemeAnalysis': <Map<String, dynamic>>[],
      'accentScore': 0.0,
      'improvementAreas': <String>[],
    };
  }
  
  Future<Map<String, dynamic>> getAccentAnalysis(String audioPath) async {
    final features = await _premiumService.getUnlockedFeatures();
    
    if (!features.contains(PremiumFeature.accentDetection)) {
      throw PremiumRequiredException('Accent detection requires AI Pro');
    }
    
    return {
      'accent': 'american',
      'score': 85.0,
      'phonemes': <String>[],
    };
  }
  
  Future<List<Map<String, dynamic>>> getPhonemeBreakdown(String audioPath) async {
    return [];
  }
  
  Future<Map<String, dynamic>> compareVoices(String userAudio, String targetAudio) async {
    return {
      'similarity': 0.0,
      'differences': <String>[],
      'tips': <String>[],
    };
  }
}

class PremiumRequiredException implements Exception {
  final String message;
  PremiumRequiredException(this.message);
  
  @override
  String toString() => message;
}

class PracticeMode {
  final String name;
  final String description;
  final bool requiresPremium;
  final IconData icon;
  
  static const kidsMode = PracticeMode(
    name: 'Kids Reading',
    description: 'Fun stories for children',
    requiresPremium: true,
    icon: Icons.child_care,
  );
  
  static const ieltsMode = PracticeMode(
    name: 'IELTS Speaking',
    description: 'Practice IELTS speaking test',
    requiresPremium: true,
    icon: Icons.school,
  );
  
  static const interviewMode = PracticeMode(
    name: 'Interview Practice',
    description: 'Job interview preparation',
    requiresPremium: true,
    icon: Icons.work,
  );
  
  const PracticeMode({
    required this.name,
    required this.description,
    required this.requiresPremium,
    required this.icon,
  });
}