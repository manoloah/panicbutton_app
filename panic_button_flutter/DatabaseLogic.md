## Table Glossary

| Table                         | Purpose                                                                            | Example Row                                                                                |
| ----------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| **breathing\_goals**          | Master tags like Calming, Energizing, Grounding—used to filter available patterns. | `{ slug: 'calming', display_name: 'Calming', sort_order: 1 }`                              |
| **breathing\_steps**          | Atomic unit: one inhale/hold/exhale cycle with a breathing method (nose or mouth). | `inhale_secs:4, inhale_method:'nose', hold_in_secs:0, exhale_secs:6, exhale_method:'nose'` |
| **breathing\_patterns**       | Song: ordered collection of steps that defines a full cycle (eg 4-6 Resonance).    | `name:'4-6 Resonance', goal_id:<uuid>, recommended_minutes:4, cycle_secs:10, slug:'coherent_4_6', is_default:true` |
| **breathing\_pattern\_steps** | Orders steps inside a pattern and sets repetitions of each step.                   | `pattern_id:<id>, step_id:<id>, position:1, repetitions:1`                                 |
| **breathing\_pattern\_status**| Tracks user progress with patterns, including total runs and time spent.           | `user_id:<id>, pattern_id:<id>, last_run:<timestamp>, total_runs:12, total_seconds:720`   |
| **breathing\_activity**       | Detailed tracking of individual breathing sessions with duration and status.       | `user_id:<id>, pattern_id:<id>, started_at:<timestamp>, duration_seconds:180, completed:true` |

Note: We have removed the previous 'routines' layer—UI will loop a single pattern to fill the user-selected minutes (1-10).

---

## Goal Ordering and Default Patterns

The breathing feature includes explicit ordering for goals and a default pattern mechanism.

### Goal Ordering

The `breathing_goals` table includes a `sort_order` column to specify the display order:

| Goal Name  | sort_order |
|------------|------------|
| Calma      | 1          |
| Equilibrio | 2          |
| Enfoque    | 3          |
| Energía    | 4          |

This ensures a consistent presentation order in the UI, regardless of database insertion order.

### Default Pattern

The `breathing_patterns` table includes an `is_default` boolean column to designate the default pattern:

```sql
-- Set coherent_4_6 as the default pattern
UPDATE breathing_patterns SET is_default = false;
UPDATE breathing_patterns SET is_default = true WHERE slug = 'coherent_4_6';
```

The application uses this field to:
1. Load a sensible default when no pattern is explicitly selected
2. Provide appropriate fallback behavior
3. Support the panic button's direct navigation to a breathing exercise

---

## Breathing Activity Tracking 