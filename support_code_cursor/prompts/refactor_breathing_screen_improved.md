# Refactor and Upgrade: Breathing Screen (panic_button_flutter)

## CONTEXT

- **Repo:** [panic_button_flutter](https://github.com/manoloah/panicbutton_app/tree/main/panic_button_flutter)
- **Relevant files:**  
    - `lib/screens/breathing_screen.dart` (main screen & UI logic)
    - `lib/providers/breathing_provider.dart` (exercise/session state)
    - `lib/providers/sound_provider.dart` (all audio)
    - `lib/widgets/goal_pattern_sheet.dart` (pattern/sound selectors)
    - `lib/models/breathing_activity.dart` and `lib/models/breathing_pattern.dart`
    - `lib/utils/audio_manager.dart` (audio engine/utils)
    - Check `breathing_player_refactor_fixes` for previous partial attempts
    - **UI/UX**: See attached image [Playing Dynamics.png] for all expected session states and button visibility.

- **Data persistence:** Breathing activity completion/stop must be written to DB via provider—see how current "finish" logic works in the provider.

---

## OBJECTIVE

### Refactor and fix `breathing_screen` and related state/audio logic so the following *is always true*:

#### CORE SESSION STATES (see attached UI):
1. **Not Started:**  
   - Shows “Start” UI and Play button.
   - Duration/pattern selectors visible.
2. **Playing:**  
   - Play button becomes Pause.
   - Duration/pattern selectors HIDDEN.
3. **Paused:**  
   - Show Play (resume) **AND** new STOP (finish) button, as in screenshot.  
   - Duration/pattern selectors stay HIDDEN.
4. **Playing Again:**  
   - Resumes from paused position.
5. **Finished (Countdown zero or STOP pressed):**  
   - Resets UI to “Start” state.  
   - (Do NOT implement a finish pop-up yet.)

---

### **MUST-HAVE FUNCTIONAL BEHAVIOR**

- **Auto-pause on navigation away**:  
  - If user leaves the screen (using Navbar or otherwise), automatically pause the session and ALL audio, and persist state:
    - *Current step, timer/second, selected music/voice/instrument, pattern*.
    - *Do not lose selections or progress*.
  - On return, restore the session (PAUSED)—sounds and state should persist; session continues from where left off, when Play is pressed.
- **No sounds should ever play outside the breathing_screen!**
- **When Paused:**  
  - UI must show a STOP button (as in image).
  - If STOP is pressed, immediately call the provider/database to finish/save the `breathing_activity` and reset everything to “Not Started.”
  - (Implement STOP so that it finishes AND records session, just like countdown-zero would.)
- **During Playing or Paused:**  
  - Duration/pattern selectors are HIDDEN (no session changes mid-run or pause).
- **Only show Play on “Not Started” and after finish.**

---

### DETAILED TECHNICAL REQUIREMENTS

- **Session State Handling:**  
    - Use the provider (or local cache if needed) to persist session progress (step, time, sound selections, pattern).
    - Restore state cleanly in `initState` or screen re-enter (NO auto-play).
- **Audio Control:**  
    - Refactor `SoundProvider` so ALL audio streams (music, cues, voice) pause on leaving the screen or pausing session.
    - Ensure no async leaks/timers keep instrument cues playing.
- **STOP Button:**  
    - Only visible in the *Paused* state.
    - Triggers session finish logic and calls provider/database to save activity immediately.
    - Resets UI and state.
- **UI/UX:**  
    - Exactly match attached screenshot for button visibility/sequence.
    - Hide duration/pattern controls as specified.
- **State Transitions:**  
    - Session only re-initializes if user selects a new pattern/duration in Not Started state.
    - Otherwise, resumes previous state and selections after navigation, even after app resume (if not killed).
- **Code Clarity:**  
    - Comment all new logic.
    - Summarize changes at the top of each edited file.
    - Follow your repo’s DEVELOPMENT_GUIDELINES.md for style and best practices.

---

## TEST CASES (Acceptance Criteria)

- Start an exercise, navigate away via Navbar, and return:
    - All audio is paused instantly, no leaks.
    - State (step, time, sound, pattern) is restored and ready to resume from pause.
    - Play resumes session, all sounds sync.
- During *Paused*, STOP button appears and works:
    - Clicking STOP saves breathing_activity to DB and resets session instantly.
- Duration/pattern cannot be changed mid-session or during pause.
- Sessions always start from Not Started; no auto-play on screen load.
- Bug regression: No instrument cue leaks, no unwanted auto-init, no reset-on-return unless STOP or countdown is finished.

---

## DELIVERABLE

- Refactored code, clean and fully commented, touching all necessary files (as listed).
- Brief code summary at the top of every changed file.
- Concise commit message:  
  `Refactor breathing_screen: auto-pause on leave, STOP button in pause, persistent session/audio state`

---

## NOTES

- Do **not** implement finished pop-up (to be done later).
- Build logic and UI exactly as shown in [Playing Dynamics.png].

---

