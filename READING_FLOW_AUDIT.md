# Reading Flow Audit Report

## 1. Why listening stops automatically while user is still reading

### Root Cause: Speech Service Final Result Handling
**File:** `lib/services/speech_service.dart:51-56`

The `speech_to_text` package sends `finalResult = true` after detecting a pause (default 3 seconds in `pauseFor` parameter). When this happens:
```dart
onResult: (result) {
  if (result.finalResult) {
    _isListening = false;
    onResult(result.recognizedWords);
    onListeningStopped?.call();  // <-- This triggers navigation immediately
  }
},
```

The `onListeningStopped` callback in `reading_screen.dart:71-76` calls `_stopTimerAndNavigate()`, which immediately navigates to results page - even if the user is just pausing between words.

### Secondary Issue: Status Callback Handling
**File:** `lib/providers/speech_provider.dart:28-38`

The `onStatusChanged` callback treats multiple statuses identically:
```dart
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
```

The status 'notListening' can fire during normal operation, not just when user stops. This causes the provider state to change unexpectedly.

---

## 2. Exact conditions that trigger result page navigation

**File:** `lib/screens/reading/reading_screen.dart:85-116`

Navigation to results (`AnalyticsScreen`) happens in `_stopTimerAndNavigate()` when:
1. Timer reaches 0 (line 45-47 in `_startTimer`)
2. `onListeningStopped` callback fires (line 71-76)
3. User manually taps stop button (line 79-83)

**The check for navigation:**
```dart
if (speechProvider.recognizedWords.isNotEmpty) {
  readingProvider.processResult(speechProvider.recognizedWords);
  Navigator.of(context).push(...AnalyticsScreen...);
} else {
  // Show "No speech detected" snackbar
}
```

---

## 3. Stop Conditions Analysis

| Condition | Currently Stops? | Should Stop? |
|-----------|-----------------|--------------|
| Timer finish | ✅ Yes (line 45-47) | ✅ Yes |
| Silence timeout (3s) | ✅ Yes (finalResult) | ❌ No - should be longer |
| Sentence completed (90%) | ⚠️ Return value ignored | ✅ Yes (with 95% threshold) |
| speech_to_text status callback | ✅ Yes (unexpectedly) | ❌ No - status 'done'/'notListening' is not user intent |
| onError callback | ✅ Yes (sets error state) | ✅ Only for fatal errors |
| Manual stop | ✅ Yes | ✅ Yes |
| Duplicate listeners | ⚠️ Possible | ❌ Should prevent |
| Widget rebuild | ⚠️ Possible | ❌ Should prevent |

---

## 4. Why "No speech detected" shows on first launch

**File:** `lib/screens/reading/reading_screen.dart:103-113`

The message shows when:
```dart
if (speechProvider.recognizedWords.isNotEmpty) {
  // Navigate to results
} else {
  // Show "No speech detected. Please try again."
}
```

**Problems:**
1. The speech recognizer needs 1-2 seconds to initialize and start capturing
2. If the user taps stop before speaking, or if the recognizer fails silently, `recognizedWords` is empty
3. No minimum session duration check - even stopping after 0.5 seconds shows this message
4. The message shows even when user deliberately stops early without speaking

---

## 5. Microphone state and UI state sync issues

### Multiple State Variables
1. **`SpeechService._isListening`** (`speech_service.dart:6`) - tracks engine state
2. **`SpeechProvider._state`** (`speech_provider.dart:15`) - enum: idle/listening/processing/completed/error
3. **`ReadingScreen._isListening`** (`reading_screen.dart:22`) - local boolean
4. **`ReadingProvider`** has no explicit listening state

### Sync Issues
- `ReadingScreen._isListening` is set to `true` on start (line 63) but only set to `false` in `_stopTimerAndNavigate`
- If `SpeechService` stops internally, the UI still shows listening state
- The `speechProvider.isListening` (line 406) reads from `SpeechProvider._state`, which can be `processing` even when engine is listening

---

## 6. Files Controlling Each Function

| Function | File | Lines |
|----------|------|-------|
| Listening state | `speech_service.dart` | 6, 48, 53, 69, 75 |
| | `speech_provider.dart` | 15-24 |
| | `reading_screen.dart` | 22 |
| Speech callbacks | `speech_service.dart` | 40-65 (onResult) |
| | `speech_provider.dart` | 51-71 (startListening) |
| | `reading_screen.dart` | 65-76 (onResult handling) |
| Timer | `reading_provider.dart` | 28-31, 90-99 |
| | `reading_screen.dart` | 38-50, 85-116 |
| Result navigation | `reading_screen.dart` | 85-116 |
| Transcript updates | `speech_provider.dart` | 59-61 |
| | `reading_provider.dart` | 118-191 |

---

## 7. Bugs Found

### Critical Bugs
1. **[BUG-01] Premature stop on pause** - `speech_service.dart:59` `pauseFor: 3s` causes finalResult too early
2. **[BUG-02] Status callback stops listening** - `speech_provider.dart:29-37` treats 'notListening' as stop
3. **[BUG-03] Navigation on finalResult** - `speech_service.dart:55` calls `onListeningStopped` immediately on finalResult
4. **[BUG-04] "No speech detected" false positive** - `reading_screen.dart:103-113` no minimum duration check
5. **[BUG-05] State desync** - Three different state variables for listening, can go out of sync

### Medium Bugs
6. **[BUG-06] Sentence completion return value ignored** - `reading_screen.dart:66-69` doesn't check `updateLiveRecognized` return value
7. **[BUG-07] No auto-restart on unexpected stop** - If recognizer stops internally, no recovery
8. **[BUG-08] Timer continues after manual stop** - `_stopTimerAndNavigate` calls `stopTimer()` but timer might fire concurrently

### Minor Issues
9. **[BUG-09] No partial results handling** - Only `finalResult` is processed, losing real-time feedback
10. **[BUG-10] `updateLiveRecognized` counts repeats incorrectly** - `reading_provider.dart:167-175` double-counts

---

## 8. Recommended Fixes

### Fix 1: Change Stopping Logic (Priority: Critical)
**File:** `speech_service.dart`

- Remove immediate `onListeningStopped` call on `finalResult`
- Process partial results for real-time feedback
- Add silence detection with 3-second threshold AFTER speech starts
- Only stop on explicit user action, timer expiry, or fatal error

### Fix 2: Improve State Management (Priority: High)
**File:** `speech_provider.dart`, `reading_screen.dart`

- Single source of truth for listening state
- Sync UI state with engine state
- Add `isSpeechStarted` flag to track if any words were captured

### Fix 3: Fix "No Speech Detected" (Priority: High)
**File:** `reading_screen.dart`

- Track session start time
- Only show message if session > 2 seconds AND no words captured
- Don't show if user manually stopped early

### Fix 4: Add Sentence Completion Check (Priority: Medium)
**File:** `reading_screen.dart`

- Use return value from `updateLiveRecognized`
- Navigate only when 95%+ words matched

### Fix 5: Add Auto-Restart (Priority: Medium)
**File:** `speech_service.dart`

- On unexpected stop (not user-initiated), restart once
- Track restart count to prevent infinite loops

### Fix 6: Remove LiveStatsHeader (Priority: Low)
**File:** `reading_screen.dart`

- Remove `LiveStatsHeader` usage
- Replace with compact reading header showing timer and status

---

## Summary

The main issue causing random auto-stop is the `speech_to_text` package's `finalResult` callback being treated as "user finished" when it's actually "pause detected". The app needs to:
1. Distinguish between user intent and recognizer behavior
2. Use a longer silence timeout (3s after speech starts)
3. Only navigate to results on explicit conditions
4. Keep UI state synced with microphone state
