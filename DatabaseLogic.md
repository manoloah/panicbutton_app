# Breathing Database Reference (v3)

This document explains the simplified Supabase schema for breath-work and shows how to add new exercises and integrate them into the UI.

---

## Table Glossary

| Table                         | Purpose                                                                            | Example Row                                                                                |
| ----------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| **breathing\_goals**          | Master tags like Calming, Energizing, Grounding—used to filter available patterns. | `{ slug: 'calming', display_name: 'Calming' }`                                             |
| **breathing\_steps**          | Atomic unit: one inhale/hold/exhale cycle with a breathing method (nose or mouth). | `inhale_secs:4, inhale_method:'nose', hold_in_secs:0, exhale_secs:6, exhale_method:'nose'` |
| **breathing\_patterns**       | Song: ordered collection of steps that defines a full cycle (eg 4-6 Resonance).    | `name:'4-6 Resonance', goal_id:<uuid>, recommended_minutes:4, cycle_secs:10, slug:'coherent_4_6'` |
| **breathing\_pattern\_steps** | Orders steps inside a pattern and sets repetitions of each step.                   | `pattern_id:<id>, step_id:<id>, position:1, repetitions:1`                                 |
| **breathing\_pattern\_status**| Tracks user progress with patterns, including total runs and time spent.           | `user_id:<id>, pattern_id:<id>, last_run:<timestamp>, total_runs:12, total_seconds:720`   |
| **breathing\_activity**       | Detailed tracking of individual breathing sessions with duration and status.       | `user_id:<id>, pattern_id:<id>, started_at:<timestamp>, duration_seconds:180, completed:true` |

Note: We have removed the previous 'routines' layer—UI will loop a single pattern to fill the user-selected minutes (1-10).

---

## Breathing Activity Tracking

The application tracks detailed breathing activities to provide accurate usage statistics and progress tracking.

### Activity Table Structure

The `breathing_activity` table stores individual session data:

| Column                     | Purpose                                                         |
| -------------------------- | --------------------------------------------------------------- |
| id                         | Unique identifier for the activity record                       |
| user_id                    | Reference to the authenticated user                             |
| pattern_id                 | The breathing pattern used during this session                   |
| started_at                 | Timestamp when the session began                                |
| duration_seconds           | Actual duration of the breathing exercise                       |
| completed                  | Whether the session was completed or abandoned                  |
| expected_duration_seconds  | Target duration selected by the user                           |
| notes                      | Optional notes about the session (for future use)               |
| created_at                 | Creation timestamp                                              |

### Pattern Status Tracking

The `breathing_pattern_status` table aggregates session data:

| Column         | Purpose                                                |
| -------------- | ------------------------------------------------------ |
| user_id        | Reference to the authenticated user                    |
| pattern_id     | Reference to the breathing pattern                     |
| last_run       | Timestamp of the most recent session                   |
| total_runs     | Count of completed sessions with this pattern          |
| total_seconds  | Cumulative seconds spent practicing this pattern       |

### Duration Requirements

For accurate statistics, we enforce minimum duration requirements:

- Sessions shorter than 10 seconds are not counted in the totals
- The trigger function enforces this rule at the database level
- UI also enforces this rule for consistency

### Database Trigger Logic

A database trigger maintains the pattern status automatically:

```sql
CREATE OR REPLACE FUNCTION update_breathing_pattern_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process activities that lasted at least 10 seconds
  IF NEW.duration_seconds >= 10 THEN
    -- Insert or update the pattern status
    INSERT INTO breathing_pattern_status (user_id, pattern_id, last_run, total_runs, total_seconds)
    VALUES (NEW.user_id, NEW.pattern_id, NEW.started_at, 1, NEW.duration_seconds)
    ON CONFLICT (user_id, pattern_id) DO UPDATE
    SET last_run = NEW.started_at,
        total_runs = breathing_pattern_status.total_runs + 1,
        total_seconds = breathing_pattern_status.total_seconds + NEW.duration_seconds;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## Breathing Journey Integration

The breathing journey feature relies on a connection between journey levels and breathing patterns. This connection is established through pattern slugs.

### Pattern Slugs

Each breathing pattern needs a unique slug in the `breathing_patterns` table:

| Column | Value                                    |
| ------ | ---------------------------------------- |
| slug   | Unique identifier (e.g. `conscious_4_4`) |

The slug should be:
- Lowercase
- Use underscores instead of spaces
- Descriptive of the pattern
- Consistently formatted

Example slugs:
- `conscious_4_4` - Conscious breathing 4-4
- `coherent_4_6` - Coherent breathing 4-6
- `triangle_4_4_4` - Triangle breathing 4-4-4

### Journey Configuration

Journey levels reference patterns via their slugs. The journey configuration (stored in `assets/data/breathing_journey_levels.json`) includes:

```json
{
  "id": 1,
  "name_es": "Botón de Alivio",
  "bolt_min": 0,
  "minutes_week": 10,
  "pattern_slugs": ["conscious_4_4"],
  "description_es": "...",
  "benefit_es": "..."
}
```

This allows the app to:
1. Display the correct pattern name for each journey level
2. Navigate directly to the pattern when the user starts an exercise
3. Maintain a consistent URL structure in the app

---

## Adding a New Breathing Pattern

Follow these steps in the Supabase Dashboard or via SQL:

### 1. Create the basic step(s)

| Column          | Value                                       |
| --------------- | ------------------------------------------- |
| inhale\_secs    | seconds (eg 4)                              |
| inhale\_method  | 'nose' or 'mouth'                           |
| hold\_in\_secs  | seconds (eg 0)                              |
| exhale\_secs    | seconds (eg 6)                              |
| exhale\_method  | 'nose' or 'mouth'                           |
| hold\_out\_secs | seconds (eg 0)                              |
| cue\_text       | Optional label (eg '4s inhale / 6s exhale') |

SQL example:

```sql
INSERT INTO breathing_steps (inhale_secs, inhale_method, hold_in_secs,
  exhale_secs, exhale_method, hold_out_secs, cue_text)
VALUES (4,'nose',0,6,'nose',0,'4s inhale / 6s exhale');
```

### 2. Create the pattern (song)

| Column               | Value                               |
| -------------------- | ----------------------------------- |
| name                 | Pattern name (eg '4-6 Resonance')   |
| goal\_id             | UUID from breathing\_goals          |
| recommended\_minutes | Default UI session length (eg 4)    |
| slug                 | Unique identifier (eg 'coherent_4_6') |

SQL example:

```sql
INSERT INTO breathing_patterns (name, goal_id, recommended_minutes, slug)
VALUES ('4-6 Resonance',
        (SELECT id FROM breathing_goals WHERE slug='calming'),
        4,
        'coherent_4_6')
RETURNING id;
```

### 3. Link steps to the pattern

| Column      | Value                        |
| ----------- | ---------------------------- |
| pattern\_id | UUID returned above          |
| step\_id    | UUID of created step         |
| position    | Order in the cycle (1,2,3,…) |
| repetitions | How many times to repeat     |

SQL example:

```sql
INSERT INTO breathing_pattern_steps (pattern_id, step_id, position, repetitions)
VALUES (<pattern_id>, <step_id>, 1, 1),
       (<pattern_id>, <other_step_id>, 2, 1);
```

After this, your new pattern will appear in the UI when a user selects that goal.

---

## Adding a Pattern to the Journey

To add a pattern to the breathing journey, ensure the pattern has a unique slug and update the journey configuration in `assets/data/breathing_journey_levels.json`:

1. **Add the pattern to Supabase** as described above, with a proper slug.
2. **Update the journey level** in the JSON file:
   ```json
   {
     "id": 5,
     "name_es": "Respiración Coherente",
     "bolt_min": 15,
     "minutes_week": 35,
     "pattern_slugs": ["coherent_4_6"],
     "description_es": "...",
     "benefit_es": "..."
   }
   ```
3. **Test the integration** by unlocking the level and confirming the pattern loads correctly.

---

## UI Integration Recipe

1. **Fetch available goals:**

```dart
final goals = await supabase.from('breathing_goals').select().execute();
```

2. **Fetch patterns for a goal:**

```dart
final patterns = await supabase
  .from('breathing_patterns')
  .select()
  .eq('goal_id', selectedGoal.id)
  .execute();
```

3. **On pattern selection:** read `recommended_minutes` and `cycle_secs`.
4. **User picks minutes (slider 1–10)** defaulting to `recommended_minutes`.
5. **Compute loops:**

```dart
final loops = (selectedMinutes * 60 / pattern.cycleSecs).ceil();
```

6. **Expand to step list:**

```dart
final list = <StepModel>[];
for (var i = 0; i < loops; i++) {
  for (final ps in pattern.steps) {
    for (var r = 0; r < ps.repetitions; r++) {
      list.add(ps.step);
    }
  }
}
```

7. **Pass `list` to your animation widget**—it drives inhale/hold/exhale timing.

---

## Journey Integration Recipe

1. **Load journey levels from JSON:**

```dart
final String jsonData = await rootBundle
    .loadString('assets/data/breathing_journey_levels.json');
final levels = parseJourneyLevels(jsonData);
```

2. **Navigate to a breathing pattern by slug:**

```dart
// Using Go Router
context.go('/breath/${level.patternSlugs.first}');
```

3. **Select a pattern by slug in the breathing screen:**

```dart
// In the BreathScreen initState
if (widget.patternSlug != null) {
  ref.read(selectedPatternProvider.notifier)
     .selectPatternBySlug(widget.patternSlug!);
}
```

4. **Get pattern name by slug:**

```dart
// In your repository
Future<String> getPatternName(String slug) async {
  final response = await _supabase
      .from('breathing_patterns')
      .select('name')
      .eq('slug', slug)
      .maybeSingle();
  
  if (response != null && response['name'] != null) {
    return response['name'] as String;
  }
  return 'Unknown Pattern';
}
```

---

## Activity Tracking Integration Recipe

1. **Create a breathing activity record when starting a session:**

```dart
Future<void> logPatternRun(String patternId, int targetMinutes) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;
  
  // Create initial record
  final activityData = {
    'user_id': userId,
    'pattern_id': patternId,
    'expected_duration_seconds': targetMinutes * 60,
    'completed': false,
    'duration_seconds': 0, // Will be updated when session completes
  };
  
  final result = await supabase
    .from('breathing_activity')
    .insert(activityData)
    .select('id')
    .single();
    
  final activityId = result['id'];
  return activityId;
}
```

2. **Update the activity when a session is completed or abandoned:**

```dart
Future<void> completeBreathingActivity(
    String activityId, int durationSeconds, bool completed) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;
  
  await supabase
    .from('breathing_activity')
    .update({
      'duration_seconds': durationSeconds,
      'completed': completed,
    })
    .eq('id', activityId)
    .eq('user_id', userId);
}
```

3. **Handle pause/resume in the UI:**

```dart
void toggleBreathing() {
  final controller = ref.read(breathingPlaybackControllerProvider.notifier);
  final isPlaying = ref.read(breathingPlaybackControllerProvider).isPlaying;
  final playbackState = ref.read(breathingPlaybackControllerProvider);
  
  if (isPlaying) {
    controller.pause();
  } else {
    // Check if we're resuming an existing session
    final hasExistingSession = playbackState.currentActivityId != null;
    
    if (!hasExistingSession) {
      // Only initialize for new sessions, not when resuming
      controller.initialize(expandedSteps, duration);
    }
    
    controller.play();
  }
}
```

4. **Track accumulated time across pause/resume cycles:**

```dart
// In your controller class
int _accumulatedSeconds = 0;

void pause() {
  _timer?.cancel();
  state = state.copyWith(isPlaying: false);
  
  // Calculate and store session time
  if (_startTime != null) {
    final sessionSeconds = DateTime.now().difference(_startTime!).inSeconds;
    _accumulatedSeconds += sessionSeconds;
    _startTime = null;
  }
}
```

---
