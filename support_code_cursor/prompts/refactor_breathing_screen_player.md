# PanicButton App — Refactor Breathing Player for Robust Pause, Resume, and Audio State

## CONTEXT

- **Repo:** panic_button_flutter (https://github.com/manoloah/panicbutton_app/tree/main/panic_button_flutter)
- **Focus:** Breathing exercise experience — pausing, resuming, and sound playback in `lib/screens/breathing_screen.dart`.
- **State:** Managed via `lib/providers/breathing_provider.dart`.
- **Audio:** Controlled via `lib/providers/sound_provider.dart` and `lib/utils/audio_manager.dart` (uses just_audio for sound playback).
- **Sound/Voice Selection:** Controlled in `lib/widgets/goal_pattern_sheet.dart`.

### Key classes/functions:
- `BreathingProvider`:
  - Holds session state, timers, current `BreathingPattern`, `BreathingActivity`.
  - Methods: `initializePattern`, `pause`, `resume`, `reset`, `completeActivity`.
- `SoundProvider`:
  - Controls three `AudioPlayer` instances: `music`, `instrument`, `voice`.
  - Methods: `playMusic`, `pauseMusic`, `disposeMusic`, etc.
  - Instrument cues use `_instrumentPlayer` (sometimes not paused on `dispose`).
- `AudioManager`:
  - Utility for managing player lifecycle and preventing leaks.
- `goal_pattern_sheet.dart`:
  - Lets user pick music/voice/instrument, calls provider setters.

---

## PROBLEM (EXACT CODE SYMPTOMS)

### When user navigates away from `breathing_screen` (e.g. using `go_router` Navbar):
- `BreathingProvider.pause()` is called, but:
    - `SoundProvider._instrumentPlayer` (for cues) sometimes **keeps playing** out of screen.
    - Other audio (music, voice) stop as expected.
    - Session state may get reset by `initializePattern` called in `initState` when returning.
- On return to `breathing_screen.dart`:
    - *Sometimes* only cues play automatically (not other audio, not animation).
    - UI is not in "paused" state; user must re-select instrument/music/voice.
    - If the exercise is changed (not default 4-6), bug is more likely.
    - Selected settings lost because provider resets on navigation rebuild (no persistence to local storage or shared preferences).

---

## REQUIRED BEHAVIOR

**1. Robust Audio Management**
- All audio players (`music`, `instrument`, `voice`) must pause/stop **instantly** on navigation away.
- No audio should continue playing when not on `breathing_screen`.
- No auto-play on return; wait for user to press Play.

**2. Persistent Session State**
- Pause session, save current step, timer, pattern, and all selected sound options.
- When returning, restore *exact* prior state, with nothing playing, until user taps Play.
- Do **not** re-initialize pattern unless user selects a new exercise.

**3. Settings Persistence**
- Music, voice, and instrument selections should persist across navigation.
- Use `SharedPreferences` (or local cache) for in-memory restore if necessary, so user never has to reselect settings unless explicitly changed.
- UI in `goal_pattern_sheet.dart` should read previous selections.

**4. Clean Lifecycle Handling**
- Ensure `dispose()` in both `BreathingProvider` and `SoundProvider` stops/clears **all** players, timers, and async tasks.
- Prevent `initializePattern` from firing on every widget rebuild; only run if pattern/exercise changes.

**5. Detailed Logging**
- Log every audio start, pause, resume, and stop, including which player.
- Log when session is paused, restored, or reset.

---

## DETAILED TASK LIST

**A. Audio Bugs**
- Refactor `SoundProvider`:
    - Make sure `pauseAll()` pauses ALL players (music, instrument, voice), regardless of current state.
    - Ensure `dispose()` kills all streams and timers, including instrument cues.
- In `breathing_screen.dart`, on `dispose` or navigation, call `pauseAll()` and save state to provider/cache.

**B. Session Resume**
- Store: current pattern, elapsed time, current step, and sound selections (music, instrument, voice) in `BreathingProvider` and/or `SharedPreferences`.
- On widget re-build, check for saved state and restore.
- On return, session is PAUSED, not auto-playing. Play resumes only if user taps Play.

**C. Sound/Voice/Instrument Setting Persistence**
- On user change, store setting in provider and also to `SharedPreferences` (or suitable cache).
- When opening `goal_pattern_sheet.dart`, load previous selection as default.

**D. Avoid Pattern Re-Init**
- `initializePattern` should only be called if:
    - Pattern has actually changed,
    - Or user explicitly pressed Reset/New Exercise.
- Otherwise, resume paused state.

**E. Test Cases**
- Play any exercise, leave with Navbar, check all audio stops.
- Return to breathing screen, check session resumes paused, with all previous settings loaded.
- Change sound/voice/instrument, repeat above, verify settings persist.
- Switch to a new exercise, ensure only then pattern re-inits.
- Try default and custom patterns.

---

## CODE STRUCTURE REQUIREMENTS

- Comment any new methods or logic.
- Follow conventions in DEVELOPMENT_GUIDELINES.md (naming, state management, file structure).
- If you introduce persistent storage, use lightweight package (e.g., `shared_preferences`).

---

## OUTPUT

- Refactored code: `breathing_screen.dart`, `breathing_provider.dart`, `sound_provider.dart`, and any related files.
- At top of each changed file, add summary of changes.
- Add concise commit message: "Fix breathing player: pause/resume, audio bug, and persistent sound settings"

---
