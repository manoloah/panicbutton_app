# Breathing Database Reference (v3)

This document explains the simplified Supabase schema for breath-work and shows how to add new exercises and integrate them into the UI.

---

## Table Glossary

| Table                         | Purpose                                                                            | Example Row                                                                                |
| ----------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| **profiles**                  | User profiles including preferences, health data, and UI state.                      | `{ username: 'JohnDoe', avatar_url: 'https://example.com/avatar.jpg' }`                     |
| **breathing\_goals**          | Master tags like Calming, Energizing, Grounding—used to filter available patterns. | `{ slug: 'calming', display_name: 'Calming' }`                                             |
| **breathing\_steps**          | Atomic unit: one inhale/hold/exhale cycle with a breathing method (nose or mouth). | `inhale_secs:4, inhale_method:'nose', hold_in_secs:0, exhale_secs:6, exhale_method:'nose'` |
| **breathing\_patterns**       | Song: ordered collection of steps that defines a full cycle (eg 4-6 Resonance).    | `name:'4-6 Resonance', goal_id:<uuid>, recommended_minutes:4, cycle_secs:10, slug:'coherent_4_6'` |
| **breathing\_pattern\_steps** | Orders steps inside a pattern and sets repetitions of each step.                   | `pattern_id:<id>, step_id:<id>, position:1, repetitions:1`                                 |
| **breathing\_pattern\_status**| Tracks user progress with patterns, including total runs and time spent.           | `user_id:<id>, pattern_id:<id>, last_run:<timestamp>, total_runs:12, total_seconds:720`   |
| **breathing\_activity**       | Detailed tracking of individual breathing sessions with duration and status.       | `user_id:<id>, pattern_id:<id>, started_at:<timestamp>, duration_seconds:180, completed:true` |
| **breath\_bolt\_scores**       | Tracks user's BOLT scores over time (measure of anxiety).                           | `user_id:<id>, score_value:75, measured_at:<timestamp>`                                    |
| **breathing\_journey\_progress**| Tracks unlocked levels in the breathing journey.                                | `user_id:<id>, level_id:<id>, unlocked:true, completed_at:<timestamp>`                     |

Note: We have removed the previous 'routines' layer—UI will loop a single pattern to fill the user-selected minutes (1-10).

---

## Breathing Goals Display and Organization

The application organizes breathing patterns under different goal categories (e.g., Calma, Equilibrio, Enfoque, Energia) to help users find the most appropriate exercise for their needs.

### Goal Data Structure

The `breathing_goals` table contains goal categories:

| Column        | Purpose                                         | Example                     |
| ------------- | ----------------------------------------------- | --------------------------- |
| id            | Unique identifier                               | UUID                        |
| slug          | Machine-readable identifier                     | "calming", "focusing"       |
| display_name  | Human-readable name in Spanish                  | "Calma", "Enfoque"          |
| description   | Optional longer description                     | "Ejercicios para relajarse" |

### Goal Display Order

Goals are displayed in a specific order in the UI to prioritize the most commonly used categories:

1. **Calma** (calming) - For relaxation and anxiety reduction
2. **Equilibrio** (grounding) - For balance and stability 
3. **Enfoque** (focusing) - For concentration and mental clarity
4. **Energía** (energizing) - For energy and activation

This order is implemented in the UI using explicit sorting, regardless of the order returned from the database:

```dart
// The preferred order is: Calma, Equilibrio, Enfoque, Energia
final preferredOrder = ['calming', 'grounding', 'focusing', 'energizing'];

// Sort goals based on the preferred order
sortedGoals.sort((a, b) {
  final indexA = preferredOrder.indexOf(a.slug);
  final indexB = preferredOrder.indexOf(b.slug);
  
  // If both slugs are found in preferred order, sort by that order
  if (indexA >= 0 && indexB >= 0) {
    return indexA.compareTo(indexB);
  }
  
  // If only one slug is found, prioritize it
  if (indexA >= 0) return -1;
  if (indexB >= 0) return 1;
  
  // Otherwise, sort alphabetically by display name
  return a.displayName.compareTo(b.displayName);
});
```

### Goal Icons

Each goal category has an associated icon for visual identification:

| Goal       | Icon                            | Usage                               |
| ---------- | ------------------------------- | ----------------------------------- |
| Calma      | `Icons.spa`                     | Relaxation and calming exercises   |
| Equilibrio | `Icons.balance`                 | Balancing and grounding exercises  |
| Enfoque    | `Icons.psychology`              | Focus and concentration exercises  |
| Energía    | `Icons.bolt`                    | Energizing and activating exercises|

Icons are consistently used across the UI to maintain visual coherence.

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

## Schema Relationships

- Each `breathing_goal` (e.g., "Calm Down") has multiple `breathing_patterns`
- Each `breathing_pattern` belongs to a specific `breathing_goal`
- Each `breathing_activity` belongs to a user (`profiles`) and a specific `breathing_pattern`
- Each `breath_bolt_score` belongs to a user (`profiles`)
- Each `breathing_journey_progress` entry belongs to a user (`profiles`)

## Sample Queries

### Getting all breathing patterns for a specific goal:

```sql
SELECT p.* 
FROM breathing_patterns p
JOIN breathing_goals g ON p.goal_id = g.id
WHERE g.name = 'Calm Down' 
ORDER BY p.difficulty_level ASC;
```

### Recording a new breathing activity:

```sql
INSERT INTO breathing_activities 
(user_id, pattern_id, duration_seconds, completed, created_at)
VALUES 
('auth.uid()', 3, 120, true, NOW());
```

### Getting a user's recent BOLT scores:

```sql
SELECT score_value, measured_at
FROM breath_bolt_scores
WHERE user_id = 'auth.uid()'
ORDER BY measured_at DESC
LIMIT 10;
```

### Updating a user's journey progress:

```sql
INSERT INTO breathing_journey_progress
(user_id, level_id, unlocked, completed_at)
VALUES
('auth.uid()', 2, true, NOW())
ON CONFLICT (user_id, level_id) 
DO UPDATE SET unlocked = true, completed_at = NOW();
```

## Security and Best Practices

### Row-Level Security (RLS)

All tables should have Row-Level Security (RLS) policies enabled to limit access to data:

```sql
-- Example RLS policy (apply to each table)
CREATE POLICY "Users can only access their own data" 
ON breathing_activities 
FOR ALL
USING (user_id = auth.uid());
```

### Secure Query Practices

1. **NEVER use string interpolation** in SQL queries:

   ```dart
   // INSECURE - DO NOT USE:
   final userInput = "O'Connor"; // SQL injection risk with quote
   final query = "SELECT * FROM profiles WHERE name = '$userInput'";
   final result = await supabase.rpc('execute_sql', { query: query });
   
   // SECURE - Use method chaining or parameters:
   final result = await supabase.from('profiles').select().eq('name', userInput);
   ```

2. **Always use Supabase's query builder methods** which automatically handle parameter binding:

   ```dart
   // Correct parameter usage:
   final response = await supabase
      .from('breathing_activities')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);
   ```

3. **Limit data exposure** by selecting only needed columns:

   ```dart
   // Get only what you need:
   final response = await supabase
      .from('profiles')
      .select('username,avatar_url')
      .eq('id', userId);
   ```

4. **Validate user input** before using in queries:

   ```dart
   // Validate input before using in query
   if (durationSeconds <= 0 || durationSeconds > 3600) {
     throw Exception('Invalid duration');
   }
   
   final response = await supabase
      .from('breathing_activities')
      .insert({
         'user_id': userId,
         'pattern_id': patternId,
         'duration_seconds': durationSeconds
      });
   ```

5. **Use RPC calls with secure parameters** for stored procedures or functions:

   ```dart
   // Correct RPC usage:
   final result = await supabase.rpc(
     'calculate_user_stats',
     params: {
       'user_id': userId,
       'days_back': 30
     }
   );
   ```

6. **Always include user ID in queries** to enforce RLS policies:

   ```dart
   // Explicitly include the user ID even if RLS would handle it
   final response = await supabase
      .from('breathing_activities')
      .select()
      .eq('user_id', supabase.auth.currentUser!.id)
      .order('created_at');
   ```

### Secure Storage of Auth Tokens

1. **Use SecureStorageService** for storing refresh tokens, never SharedPreferences:

   ```dart
   // Storing tokens securely
   await secureStorage.storeRefreshToken(refreshToken);
   
   // Retrieving tokens securely
   final refreshToken = await secureStorage.getRefreshToken();
   ```

2. **Implement token refresh** properly using secure storage:

   ```dart
   Future<void> refreshSession() async {
     try {
       final refreshToken = await secureStorage.getRefreshToken();
       if (refreshToken != null) {
         final response = await supabase.auth.refreshSession(refreshToken);
         // Store new tokens
         await secureStorage.storeRefreshToken(response.refreshToken);
       }
     } catch (e) {
       // Handle refresh error
     }
   }
   ```

## Migrations and Schema Updates

When updating the database schema, always use migrations:

1. Create a new migration file in `/migrations` with timestamp prefix
2. Test the migration on a development instance first
3. Apply the migration using Supabase CLI or dashboard
4. Document the changes in the code

Example migration:

```sql
-- migrations/20240715_add_reminder_settings.sql
ALTER TABLE profiles 
ADD COLUMN reminder_enabled BOOLEAN DEFAULT false,
ADD COLUMN reminder_time TIME DEFAULT '08:00:00';
```

## Testing Database Operations

1. Create test fixtures with known test data
2. Use a dedicated test database for integration tests
3. Reset the database state between test runs
4. Include both positive and negative test cases (input validation, error handling)
5. Test RLS policies by simulating different user contexts

Example test pattern:

```dart
test('User can only access their own activities', () async {
  // Login as user 1
  await supabase.auth.signIn(email: 'user1@example.com', password: 'password');
  final user1Id = supabase.auth.currentUser!.id;
  
  // Create activity for user 1
  await supabase.from('breathing_activities').insert({
    'user_id': user1Id,
    'pattern_id': 1,
    'duration_seconds': 60
  });
  
  // Login as user 2
  await supabase.auth.signOut();
  await supabase.auth.signIn(email: 'user2@example.com', password: 'password');
  
  // Try to access user 1's activities - should return empty array
  final response = await supabase.from('breathing_activities')
    .select().eq('user_id', user1Id);
  
  // Should be empty due to RLS
  expect(response.data, isEmpty);
});
```

---

## Critical Step Ordering Requirements

### Issue: Steps Not Respecting Position Order

**Problem**: Breathing patterns like "Triángulo Invertido" were sometimes playing steps in random order instead of following the `breathing_pattern_steps.position` column order defined in the database.

**Root Cause**: PostgreSQL does not guarantee any particular order when returning joined data unless an explicit `ORDER BY` clause is used. The original queries were missing proper ordering for the `breathing_pattern_steps` relation.

**Impact**: This caused breathing exercises to play in incorrect sequences, making patterns like triangle breathing or other complex sequences ineffective or confusing for users.

### Solution Implemented

**Database Query Fix**: Added explicit ordering by position in all pattern fetching methods:

```dart
// BEFORE (incorrect - no guaranteed order)
final patternData = await _supabase
    .from('breathing_patterns')
    .select('*, breathing_pattern_steps!inner(*, breathing_steps(*))')
    .eq('id', patternId)
    .single();

// AFTER (correct - explicitly orders by position)
final patternData = await _supabase
    .from('breathing_patterns')
    .select('*, breathing_pattern_steps!inner(*, breathing_steps(*))')
    .eq('id', patternId)
    .order('breathing_pattern_steps.position', ascending: true)
    .single();
```

**Application-Level Sorting**: Added redundant sorting in the application layer as a safety net:

```dart
// Sort pattern steps by position before processing to ensure correct order
final sortedPatternSteps = List<Map<String, dynamic>>.from(patternSteps);
sortedPatternSteps.sort((a, b) {
  final positionA = a['position'] as int? ?? 0;
  final positionB = b['position'] as int? ?? 0;
  return positionA.compareTo(positionB);
});
```

**Enhanced Debugging**: Added comprehensive logging to track step processing order:

```dart
debugPrint('🔄 Processing ${sortedPatternSteps.length} steps in correct order for pattern: ${patternData['name']}');

for (final stepData in sortedPatternSteps) {
  final stepPosition = stepData['position'] as int? ?? 0;
  debugPrint('  Step ${stepPosition}: ${step.cueText} - inhale:${step.inhaleSecs}s, hold:${step.holdInSecs}s, exhale:${step.exhaleSecs}s, hold:${step.holdOutSecs}s (${stepRepetitions} reps)');
}
```

### Methods Updated

1. **`expandPattern()`** - Primary fix for step expansion used during breathing exercises
2. **`getPatternsByGoal()`** - Ensures consistent ordering when browsing patterns
3. **`getPatternBySlug()`** - Ensures consistent ordering when accessing specific patterns

### Testing and Validation

**Debug Utility**: Added `debugPatternStepOrder()` method to validate step ordering:

```dart
// Usage example to test pattern ordering
final repository = ref.read(breathRepositoryProvider);
await repository.debugPatternStepOrder('triangulo-invertido');
```

**Verification Steps**:
1. Check console logs show steps in correct position order (1, 2, 3, etc.)
2. Verify breathing exercises follow the intended sequence
3. Test complex patterns like triangle breathing maintain proper step flow

### Prevention Guidelines

**For Database Design**:
- Always define position columns with proper constraints
- Use CHECK constraints to ensure position uniqueness within a pattern
- Consider using auto-incrementing position values

**For Query Development**:
- Always include `ORDER BY position` when fetching pattern steps
- Use explicit column names in ORDER BY clauses for joined tables
- Add application-level sorting as a safety net for critical sequences

**For Testing**:
- Create patterns with distinct timing to easily identify if steps are out of order
- Test with patterns that have 3+ steps to catch ordering issues
- Use the debug utility when adding new patterns to validate step flow

### Database Constraints Recommendation

Consider adding these constraints to prevent future ordering issues:

```sql
-- Ensure position values are unique within each pattern
ALTER TABLE breathing_pattern_steps 
ADD CONSTRAINT unique_pattern_position 
UNIQUE (pattern_id, position);

-- Ensure position values start from 1 and are sequential
ALTER TABLE breathing_pattern_steps 
ADD CONSTRAINT valid_position_range 
CHECK (position > 0);
```

This fix ensures that all breathing patterns will consistently play their steps in the correct order as defined in the database, providing users with the intended breathing experience.

---
