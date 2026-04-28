# Pronunciation App

A professional Flutter application that helps users improve their reading accuracy and pronunciation while reading text aloud. The app uses on-device speech recognition and provides real-time feedback with detailed analytics.

## Features

### Free Mode
- **Live Speech Recognition**: Real-time speech-to-text using on-device processing
- **Live Word Highlighting**: Words are highlighted as you speak with color-coded feedback:
  - 🟢 Green = Correct word spoken
  - 🔴 Red = Wrong word (different from expected)
  - 🟠 Orange = Missed word (not spoken)
  - ⚪ Gray = Pending (not yet spoken)
- **Live Progress Tracking**: Real-time progress bar showing completion percentage
- **Live Counters**: Correct, Wrong, and Remaining word counts
- **Countdown Timer**: Selectable reading time (15/30/45/60 seconds)
- **Live Timer Display**: Shows remaining time with visual warnings
- **Text-to-Speech**: Hear the correct pronunciation
- **Detailed Analytics**: Accuracy, Completion, and Fluency scores
- **Comparison View**: Side-by-side target vs spoken text

### AI Pro Mode (Coming Soon)
- Word-by-word pronunciation scoring
- Accent detection (American/British)
- Phoneme analysis
- Voice replay comparison
- Progress charts
- Daily challenges
- Kids reading mode
- IELTS speaking practice
- Interview preparation mode

## How It Works

### 1. Reading Screen Flow

```
┌─────────────────────────────────────┐
│           Reading Screen             │
├─────────────────────────────────────┤
│  Timer Selector: [30 sec ▼]         │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Live Stats Header          │    │
│  │ ✓ Correct: 3  ✗ Wrong: 0 │    │
│  │ ○ Remaining: 5  [====--] │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Sentence Card               │    │
│  │ 🟢 The 🟢 cat 🔴 is ⚪    │    │
│  │ ⚪ sitting ⚪ on ⚪ the    │    │
│  │ ⚪ mat                   │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ "You said: the cat tree"   │    │
│  └─────────────────────────────┘    │
│                                     │
│       ⏱ 00:27 remaining            │
│                                     │
│          [ 🎤 MIC BUTTON ]         │
│         Tap to start/stop            │
│                                     │
│    [ 🔊 Hear Correct ]           │
└─────────────────────────────────────┘
```

### 2. Timer System

The app includes a countdown timer for reading practice:

- **Before Start**: User can select reading time (15/30/45/60 seconds)
- **During Reading**: Timer counts down with visual feedback
  - Turns orange/red when 5 seconds remaining
- **Auto-Stop**: Listening stops when:
  - Timer reaches 0
  - User taps Stop
  - Sentence is completed (90%+ words spoken)

### 3. Word Matching Logic

The app compares spoken words with expected words in real-time:

```
Expected: "The cat is sitting on the mat"
Spoken:   "The cat tree sitting on mat"

Comparison:
"The"    → "the"    → ✓ Correct (Green)
"cat"    → "cat"    → ✓ Correct (Green)
"is"     → "tree"   → ✗ Wrong (Red)
"sitting"→ "sitting"→ ✓ Correct (Green)
"on"     → "on"     → ✓ Correct (Green)
"the"    → "the"    → ✓ Correct (Green)
"mat"    → "mat"    → ✓ Correct (Green)
```

### 4. Scoring System

Three scores are calculated:

| Score | Formula | Description |
|-------|---------|------------|
| **Accuracy** | (Correct Words / Total Expected) × 100 | How many words were pronounced correctly |
| **Completion** | (Spoken Words / Total Expected) × 100 | How much of the sentence was read |
| **Fluency** | Base - (Pauses × 5) - (Repeats × 8) + Speed Bonus | How smooth the reading was |

### 5. Timer Analytics

On the results page, timer performance is shown:

```
Allocated Time: 30 sec
Used Time: 18 sec
[⚡ Fast Reader!] badge if completed early
[⏰ Time Over] badge if timed out
```

### 6. Results Screen

After completion, users see detailed results:

```
┌─────────────────────────────────────┐
│            Results Screen            │
├─────────────────────────────────────┤
│          🎉 Excellent!            │
│                                     │
│        ┌─────────────┐             │
│        │   85%      │             │
│        │  Accuracy  │             │
│        └─────────────┘             │
│                                     │
│  Accuracy: 85%  Completion: 100%   │
│  Fluency: 78%                       │
│                                     │
│  Timer: 18 sec used / 30 sec        │
│  [⚡ Fast Reader!]                 │
│                                     │
│  Comparison:                       │
│  Target:  "The cat is sitting..."   │
│  You Said: "The cat tree sit..."    │
│                                     │
│  Words to Improve:                  │
│  [ is ] [ mat ]                   │
│                                     │
│  Tips:                            │
│  • Focus on "is"                 │
│  • ⚡ Great speed!               │
│                                     │
│     [ 🔄 Try Again ]              │
│     [ 🔊 Hear Correct ]           │
└─────────────────────────────────────┘
```

## Technical Architecture

### Project Structure

```
lib/
├── main.dart                    # App entry point
├── core/
│   ├── theme/
│   │   └── app_theme.dart       # Material 3 theme & colors
│   ├── constants/
│   │   └── app_constants.dart # App constants
│   └── utils/
│       └── text_utils.dart    # Text utilities
├── models/
│   ├── word_match.dart        # Word match model
│   └── reading_result.dart    # Result model
├── services/
│   ├── speech_service.dart    # Speech-to-text
│   ├── tts_service.dart       # Text-to-speech
│   ├── comparison_service.dart# Word matching
│   └── premium_service.dart   # Premium features
├── providers/
│   ├── speech_provider.dart   # Speech state
│   └── reading_provider.dart  # Reading state + timer
├── widgets/
│   ├── reading_text_view.dart  # Highlighted text
│   ├── live_stats_card.dart    # Stats display
│   ├── mic_button.dart        # Animated mic
│   └── ...
└── screens/
    ├── splash/               # Splash screen
    ├── home/                  # Home screen
    ├── reading/               # Practice screen
    ├── analytics/             # Results screen
    ├── premium/               # Premium screen
    └── settings/              # Settings
```

### Key Features Implemented

1. **Timer System**
   - `Timer.periodic` for countdown
   - Selectable durations (15/30/45/60 sec)
   - Auto-stops on timer expiry

2. **Live Features**
   - Real-time word highlighting
   - Live spoken text display
   - Live progress tracking
   - Live countdown display

3. **State Management**
   - `SpeechProvider`: Speech recognition state
   - `ReadingProvider`: Reading session + timer state

4. **Auto-Stop Conditions**
   - Timer reaches 0
   - Sentence completed (90%+)
   - User taps Stop

## Installation

### Prerequisites

1. Flutter SDK 3.x+
2. Android SDK for Android builds

### Steps

```bash
# Clone the repository
cd pronunciation_app

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

### Permissions Required

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
```

## Premium Features Architecture

The app is designed to support future premium features:

```dart
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
```

## Troubleshooting

### Timer Not Working
- Check that microphone permission is granted
- Ensure app has foreground permission

### Live Highlights Not Updating
- Speech recognition must receive partial results
- Check network if using first-time model

### Recognition Too Slow
- Close other apps using microphone
- Try in quieter environment

## Version History

### v1.1.0 - Timer Update
- Added countdown timer (15/30/45/60 sec)
- Live timer display with warnings
- Auto-stop on timer/completion
- Timer analytics in results
- Live spoken text display
- Comparison view

### v1.0.0 - Initial Release
- Basic speech recognition
- Word highlighting
- Analytics screen

## Credits

- [speech_to_text](https://pub.dev/packages/speech_to_text) - Speech recognition
- [flutter_tts](https://pub.dev/packages/flutter_tts) - Text to speech
- [provider](https://pub.dev/packages/provider) - State management
- [google_fonts](https://pub.dev/packages/google_fonts) - Typography

---

Made with ❤️ using Flutter