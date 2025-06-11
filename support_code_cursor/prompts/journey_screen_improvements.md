# \[Feature Request] Journey Experience Refactor & Exercise Locking – PanicButton App

**Target file(s):**

* `lib/screens/journey_screen.dart`
* `lib/screens/breathing_screen.dart`
* Any relevant model or provider files (see below)

**Background:**
The current Journey progression logic is causing friction—too few users are progressing. There are known issues with *minutes tracking* and how *breathing\_activity* is recorded on the journey. We want to simplify level progression and make the experience much more rewarding and clear.

This refactor is aimed at both fixing the minute tracking bug and implementing a new logic for unlocking levels and exercises. Additionally, exercises need to be visually locked in the breathing screen until the user unlocks them.

---

## 🎯 Goals

1. **Fix and improve the calculation for Journey Level progression:**

   * Ensure accurate minute tracking per user (breathing\_activity) and correct assignment of level.
   * Use *cumulative minutes* for unlocking, not per-week streaks.
2. **Update Level Unlock Logic:**

   * BOLT score minimum (keep as is).
   * Cumulative minutes of breathing activities completed (see new formula).
   * User must complete at least 3 minutes of the specific *unlocked exercise* of the previous level.
3. **Lock Exercises UI/UX:**

   * On `/breathing_screen`, show a lock icon for exercises the user hasn’t unlocked.
   * If user taps the lock, show a clear popup:
     `"Alcanza el nivel X de tu camino de respiración para desbloquear esta respiración"`

---

## 📋 Requirements & Acceptance Criteria

### 1. **Fix Minute Tracking & Level Calculation**

* **Review & update tracking logic:**
  The tracking of minutes is currently buggy and isn’t always updated after each breathing session (especially when returning from `breath_screen` to `journey_screen`).
* **Expected behavior:**

  * Each time a user completes a breathing session, their total minutes are accurately updated.
  * This should use the `breathing_activity` model/table (see `/providers/activity_provider.dart` or related).
  * When loading `/journey_screen`, levels and progress must reflect the latest, *cumulative* data.

**Reference:**

* Chat log: [https://chatgpt.com/s/cd\_6849085b984c819183623bfc6ee6f3df](https://chatgpt.com/s/cd_6849085b984c819183623bfc6ee6f3df)
* Recent Codex branch: `codex/update-rls-policy,-refresh-progress,-and-handle-weekly-minut`

---

### 2. **New Level Unlock Logic**

Replace the old *"minutes per week for X consecutive weeks"* logic with the following:

* **BOLT Score**: User's current BOLT score must be at least the level’s minimum.

* **Cumulative Minutes:**

  > `Cumulative minutes required = (Level Number) × (Minutes required for that level)`

  *Example for level 4:*

  * Level number: 4
  * Minutes required for level: 25
  * **Cumulative minutes required:** 4 × 25 = 100

* **Completed at least 3 minutes of the previous level's unlocked exercise:**

  * The user must have completed *at least 3 minutes* of the breathing exercise they unlocked in the previous level.
  * This should be tracked in user activity (you may need to add an identifier for "exercise\_slug" or similar to the activity record).

#### **Edge Case Examples**

* If the user skips an exercise but meets total minutes, they **should not** advance until they’ve done at least 3 min of the *last* unlocked exercise.
* The minutes tracked must only count actual, breathing time—not time spent on the screen.

#### **Technical Notes**

* Level definitions are found in the  `panic_button_flutter/assets/data/breathing_journey_levels.json` array/object.
* Activity history is tracked via `breathing_activity` (database or provider).
* BOLT score is already implemented—just use current logic.

---

### 3. **Exercise Locking in UI**

* On `/breathing_screen`, exercises that are not unlocked yet must show a *lock* icon.
* The user should not be able to start a locked exercise.
* On tapping a locked exercise, show a simple modal or dialog:

  > `"Alcanza el nivel X de tu camino de respiración para desbloquear esta respiración"`

#### **UX Acceptance**

* Unlocked exercises show as normal (play/start enabled).
* Locked exercises have a grayed out or lock overlay (consistent with current app style).
* Dialog is dismissible, simple, and reuses app theme.

---

## 🛠️ Files / Components to Review or Update

* `lib/screens/journey_screen.dart` — Level display, progression logic.
* `lib/providers/activity_provider.dart` — Breathing activity storage/tracking.
* `lib/screens/breathing_screen.dart` — Exercise list, locking logic.
* Models for journey/exercises (e.g., `lib/models/journey_level.dart`, etc.).

\*\*If needed, update the backend schema and Supabase sync to support new activity fields. Use the Supabase MCP for this but double check and make sure this is correct since these changes are not reversible. \*\*

---

## 🧑‍💻 Implementation Steps (Summary)
1. **Create a new branch**

1. **Refactor minute tracking:**

   * Ensure breathing\_activity is updated after every session.
   * Calculate and display cumulative minutes.
2. **Refactor level progression logic:**

   * New criteria as described.
   * Add check for "3 minutes of previous exercise."
3. **Implement exercise lock UI:**

   * Lock + popup per above.
   * Ensure locked exercises are not selectable.
4. **Test & Validate:**

   * Test with users at different stages/levels.
   * Ensure all progress is correctly tracked and reflected in both screens.

5. **Create PR **
    * Do not merge I will merge once everything is tested on my side and works and can be merged. 

---

## 📝 References

* [Journey Screen (journey\_screen.dart)](https://github.com/manoloah/panicbutton_app/blob/main/panic_button_flutter/lib/screens/journey_screen.dart)
* [Breathing Screen](https://github.com/manoloah/panicbutton_app/blob/main/panic_button_flutter/lib/screens/breathing_screen.dart)
* [Codex branch for previous patch](https://github.com/manoloah/panicbutton_app/tree/codex/update-rls-policy,-refresh-progress,-and-handle-weekly-minut)

---

## ✅ Deliverable

A PR with:

* All minute tracking and level logic updated to match above.
* Proper exercise locking in `/breathing_screen`.
* All changes tested you can use flutter -d chrome to test. 
